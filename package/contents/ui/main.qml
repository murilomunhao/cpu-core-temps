/*
    SPDX-FileCopyrightText: 2026 Murilo Munhao
    SPDX-License-Identifier: MIT
*/


import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    // Texto direto na barra (sem ícone + popup)
    preferredRepresentation: fullRepresentation

    property int warningTemp: Plasmoid.configuration.warningTemp
    property int criticalTemp: Plasmoid.configuration.criticalTemp
    property int updateMs: Math.max(1, Plasmoid.configuration.updateInterval) * 1000
    property bool showUnit: Plasmoid.configuration.showUnit
    property bool showCoreLabel: Plasmoid.configuration.showCoreLabel
    property int fontSize: Plasmoid.configuration.fontSize
    property string separator: (Plasmoid.configuration.separator !== undefined && Plasmoid.configuration.separator !== null)
                               ? Plasmoid.configuration.separator
                               : " "

    // Cores distintas por núcleo físico (estado normal)
    readonly property var baseColors: [
        "#4FC3F7", "#81C784", "#FFD54F", "#BA68C8",
        "#4DB6AC", "#FF8A65", "#64B5F6", "#AED581",
        "#F06292", "#9575CD", "#4DD0E1", "#DCE775",
        "#FFB74D", "#A1887F", "#90A4AE", "#E57373"
    ]

    // IDs lógicos representativos de cada núcleo FÍSICO (ex.: 0, 1, 2, 3)
    property var physicalCpuIds: []
    property var sensorItems: []
    property bool discoveryDone: false

    ListModel {
        id: tempsModel
    }

    function colorForCore(index, temp) {
        if (temp === undefined || temp === null || isNaN(temp))
            return Kirigami.Theme.disabledTextColor

        if (temp >= criticalTemp)
            return "#FF1744"

        if (temp >= warningTemp) {
            var t = Math.min(1.0, (temp - warningTemp) / Math.max(1, criticalTemp - warningTemp))
            var r = 255
            var g = Math.round(152 * (1 - t) + 23 * t)
            var b = Math.round(0 * (1 - t) + 68 * t)
            return Qt.rgba(r / 255, g / 255, b / 255, 1)
        }

        return baseColors[index % baseColors.length]
    }

    function formatTemp(temp) {
        if (temp === undefined || temp === null || isNaN(temp))
            return "--"
        var n = Math.round(Number(temp))
        return showUnit ? (n + "°") : ("" + n)
    }

    function rebuild() {
        for (var i = 0; i < sensorItems.length; ++i) {
            if (sensorItems[i])
                sensorItems[i].destroy()
        }
        sensorItems = []
        tempsModel.clear()

        for (var j = 0; j < physicalCpuIds.length; ++j) {
            var cpuId = physicalCpuIds[j]
            var sensorId = "cpu/cpu" + cpuId + "/temperature"
            tempsModel.append({
                coreIndex: j,
                cpuId: cpuId,
                sensorId: sensorId,
                temp: Number.NaN
            })
            var obj = sensorComp.createObject(root, {
                sensorId: sensorId,
                coreIndex: j
            })
            sensorItems.push(obj)
        }
        updateTooltip()
    }

    function updateTooltip() {
        var lines = []
        for (var i = 0; i < tempsModel.count; ++i) {
            var item = tempsModel.get(i)
            lines.push("Núcleo " + i + " (cpu" + item.cpuId + "): "
                       + formatTemp(item.temp) + (showUnit ? "C" : " °C"))
        }
        if (lines.length === 0) {
            toolTipMainText = i18n("CPU Core Temps")
            toolTipSubText = i18n("Aguardando sensores de núcleos físicos…\nVerifique lm_sensors e ksystemstats.")
        } else {
            toolTipMainText = i18n("Temperaturas dos núcleos físicos (%1)", tempsModel.count)
            toolTipSubText = lines.join("\n")
        }
    }

    Component {
        id: sensorComp
        Sensors.Sensor {
            property int coreIndex: 0
            updateRateLimit: root.updateMs

            onValueChanged: {
                if (coreIndex >= 0 && coreIndex < tempsModel.count) {
                    tempsModel.setProperty(coreIndex, "temp", value)
                    root.updateTooltip()
                }
            }
        }
    }

    // Descobre 1 CPU lógico por núcleo físico via topologia do kernel
    // (thread_siblings_list). Assim threads HT/SMT do mesmo núcleo
    // são agrupadas e só um representante é usado.
    Plasma5Support.DataSource {
        id: topologySource
        engine: "executable"
        connectedSources: []

        onNewData: function (sourceName, data) {
            disconnectSource(sourceName)

            var out = (data["stdout"] || "").trim()
            if (!out) {
                // Fallback: tenta lscpu
                if (sourceName.indexOf("thread_siblings") !== -1) {
                    connectSource(lscpuCmd)
                    return
                }
                // Último recurso: cpu0 apenas
                physicalCpuIds = [0]
                discoveryDone = true
                rebuild()
                return
            }

            var ids = out.split(/\s+/).map(function (s) {
                return parseInt(s, 10)
            }).filter(function (n) {
                return !isNaN(n) && n >= 0
            })

            // Ordena e remove duplicados
            ids.sort(function (a, b) { return a - b })
            var unique = []
            for (var i = 0; i < ids.length; ++i) {
                if (unique.length === 0 || unique[unique.length - 1] !== ids[i])
                    unique.push(ids[i])
            }

            if (unique.length === 0)
                unique = [0]

            physicalCpuIds = unique
            discoveryDone = true
            rebuild()
            // Remove sensores sem valor real após alguns segundos
            pruneTimer.start()
        }

        function discover() {
            connectSource(siblingsCmd)
        }
    }

    // Um ID por grupo de siblings (menor número do grupo = representante do núcleo físico)
    readonly property string siblingsCmd:
        "bash -c '" +
        "for d in /sys/devices/system/cpu/cpu[0-9]*; do " +
        "  [ -f \"$d/topology/thread_siblings_list\" ] || continue; " +
        "  list=$(cat \"$d/topology/thread_siblings_list\"); " +
        "  first=$(echo \"$list\" | cut -d, -f1 | cut -d- -f1); " +
        "  echo \"$first\"; " +
        "done | sort -n | uniq" +
        "'"

    // Alternativa se /sys não estiver acessível como esperado
    readonly property string lscpuCmd:
        "bash -c '" +
        "lscpu -p=CPU,CORE,SOCKET 2>/dev/null | grep -v \"^#\" | " +
        "awk -F, '\\''!seen[$2\",\"$3]++ {print $1}'\\''" +
        "'"

    Connections {
        target: Plasmoid.configuration
        function onUpdateIntervalChanged() {
            for (var i = 0; i < sensorItems.length; ++i) {
                if (sensorItems[i])
                    sensorItems[i].updateRateLimit = root.updateMs
            }
        }
        function onShowUnitChanged() { root.updateTooltip() }
        function onWarningTempChanged() { root.updateTooltip() }
        function onCriticalTempChanged() { root.updateTooltip() }
    }

    Timer {
        id: pruneTimer
        interval: 4000
        repeat: false
        onTriggered: {
            // Mantém apenas núcleos que reportaram temperatura válida
            var validIds = []
            for (var i = 0; i < sensorItems.length; ++i) {
                var s = sensorItems[i]
                if (s && s.value !== undefined && s.value !== null
                        && !isNaN(s.value) && s.value > 1 && s.value < 150) {
                    validIds.push(physicalCpuIds[i])
                }
            }
            if (validIds.length > 0 && validIds.length !== physicalCpuIds.length) {
                physicalCpuIds = validIds
                rebuild()
            } else if (validIds.length === 0 && physicalCpuIds.length > 0) {
                // Nenhum cpu/cpuN/temperature — tenta média do pacote
                // (comum em alguns AMD). Mostra um único valor.
                physicalCpuIds = []
                for (var j = 0; j < sensorItems.length; ++j) {
                    if (sensorItems[j])
                        sensorItems[j].destroy()
                }
                sensorItems = []
                tempsModel.clear()
                tempsModel.append({
                    coreIndex: 0,
                    cpuId: "all",
                    sensorId: "cpu/all/averageTemperature",
                    temp: Number.NaN
                })
                var avg = sensorComp.createObject(root, {
                    sensorId: "cpu/all/averageTemperature",
                    coreIndex: 0
                })
                sensorItems.push(avg)
                updateTooltip()
            }
        }
    }

    Component.onCompleted: {
        topologySource.discover()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: contentRow.implicitWidth + Kirigami.Units.smallSpacing
        Layout.preferredWidth: contentRow.implicitWidth + Kirigami.Units.smallSpacing
        Layout.minimumHeight: Kirigami.Units.iconSizes.small
        Layout.preferredHeight: Math.max(contentRow.implicitHeight, Kirigami.Units.iconSizes.small)

        Row {
            id: contentRow
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            spacing: 0

            Repeater {
                model: tempsModel

                Row {
                    spacing: 0

                    Text {
                        visible: index > 0
                        text: root.separator
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: root.fontSize > 0 ? root.fontSize : Kirigami.Theme.defaultFont.pixelSize
                        font.family: Kirigami.Theme.defaultFont.family
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: (root.showCoreLabel ? ("C" + index + ":") : "") + formatTemp(model.temp)
                        color: colorForCore(index, model.temp)
                        font.pixelSize: root.fontSize > 0 ? root.fontSize : Kirigami.Theme.defaultFont.pixelSize
                        font.family: Kirigami.Theme.defaultFont.family
                        font.bold: !isNaN(model.temp) && model.temp >= root.warningTemp
                        verticalAlignment: Text.AlignVCenter

                        Behavior on color {
                            ColorAnimation { duration: 250 }
                        }
                    }
                }
            }

            Text {
                visible: tempsModel.count === 0
                text: discoveryDone ? i18n("CPU ?°") : i18n("CPU…")
                color: Kirigami.Theme.disabledTextColor
                font.pixelSize: root.fontSize > 0 ? root.fontSize : Kirigami.Theme.defaultFont.pixelSize
            }
        }
    }
}
