/*
    SPDX-FileCopyrightText: 2026 Murilo Munhao
    SPDX-License-Identifier: MIT
*/


import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_warningTemp: warningSpin.value
    property alias cfg_criticalTemp: criticalSpin.value
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_showUnit: showUnitCheck.checked
    property alias cfg_showCoreLabel: showLabelCheck.checked
    property alias cfg_fontSize: fontSizeSpin.value
    property alias cfg_separator: separatorField.text

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: warningSpin
            Kirigami.FormData.label: i18n("Temperatura de aviso (°C):")
            from: 40
            to: 100
            stepSize: 1
        }

        QQC2.SpinBox {
            id: criticalSpin
            Kirigami.FormData.label: i18n("Temperatura crítica (°C):")
            from: 50
            to: 120
            stepSize: 1
        }

        QQC2.SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: i18n("Intervalo de atualização (s):")
            from: 1
            to: 30
            stepSize: 1
        }

        QQC2.CheckBox {
            id: showUnitCheck
            Kirigami.FormData.label: i18n("Mostrar unidade (°C):")
            text: i18n("Sim")
        }

        QQC2.CheckBox {
            id: showLabelCheck
            Kirigami.FormData.label: i18n("Mostrar rótulo do núcleo:")
            text: i18n("Ex.: C0: 45°")
        }

        QQC2.SpinBox {
            id: fontSizeSpin
            Kirigami.FormData.label: i18n("Tamanho da fonte (0 = automático):")
            from: 0
            to: 24
            stepSize: 1
        }

        QQC2.TextField {
            id: separatorField
            Kirigami.FormData.label: i18n("Separador entre núcleos:")
            placeholderText: i18n("espaço")
        }
    }
}
