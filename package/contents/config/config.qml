/*
    SPDX-FileCopyrightText: 2026 Murilo Munhao
    SPDX-License-Identifier: MIT
*/

import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Geral")
        icon: "configure"
        source: "configGeneral.qml"
    }
}
