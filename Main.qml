import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    width: 400
    height: 750
    visible: true
    title: "My AI Finance"
    color: "#0D0D12"

    ListModel { id: historyModel }

    Connections {
        target: cppBackend

        function onTransactionAdded(type, amount, desc, time) {
            historyModel.insert(0, { "txType": type, "txAmount": amount, "txDesc": desc, "txTime": time })
        }

        function onApiError(errorMsg) {
            errorDialog.text = errorMsg
            errorDialog.open()
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: homePage

        pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 300 } }
        pushExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 300 } }
    }

    Component {
        id: homePage
        Page {
            background: Rectangle { color: "transparent" }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 48

                // Top: App Name
                Label {
                    text: "My AI Finance"
                    color: "#FFFFFF"
                    font.pixelSize: 32
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }

                // Middle: Enter Dashboard Button
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 220
                    height: 56
                    radius: 28 // Pill shape

                    // AI Gradient Background
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#8B5CF6" } // Purple
                        GradientStop { position: 1.0; color: "#3B82F6" } // Blue
                    }

                    // Subtle Glow Effect via Border
                    border.color: "#8B5CF6"
                    border.width: 1

                    Label {
                        text: "Enter Dashboard"
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: stackView.push(dashboardPage)
                        onPressed: parent.opacity = 0.8
                        onReleased: parent.opacity = 1.0
                    }
                }
            }

            // Bottom: Credit Line
            Label {
                text: "Made by ZayanDev — a personal side project"
                color: "#9CA3AF"
                font.pixelSize: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    // ==========================================
    // SCREEN 2: DASHBOARD
    // ==========================================
    Component {
        id: dashboardPage
        Page {
            background: Rectangle { color: "transparent" }

            // --- MAIN CONTENT ---
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 32

                // TOP HEADER
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "My AI Finance"
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "API"
                        font.pixelSize: 12
                        font.bold: true
                        background: Rectangle { color: "#1C1C24"; radius: 8; border.color: "#2A2A35"; implicitWidth: 50; implicitHeight: 32 }
                        palette.buttonText: "#9CA3AF"
                        onClicked: apiPopup.open()
                    }
                }

                // BALANCE SECTION (Massive & Dominant)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        text: "Total Balance"
                        color: "#9CA3AF"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Label {
                        // Automatically updates when C++ emits balanceChanged
                        text: cppBackend.currentBalance
                        color: "#FFFFFF"
                        font.pixelSize: 48
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // TRANSACTIONS SECTION (Card Layout)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1C1C24" // Elevated Surface
                    radius: 16
                    border.color: "#2A2A35"
                    clip: true

                    ListView {
                        id: transactionList
                        anchors.fill: parent
                        anchors.margins: 8
                        model: historyModel
                        spacing: 4

                        delegate: Rectangle {
                            id: rowContainer
                            width: ListView.view.width
                            height: isExpanded ? 90 : 60
                            color: "transparent"
                            radius: 8

                            property bool isExpanded: false
                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }

                            // BACKGROUND CLICK AREA (Fixed: Placed under the Delete button)
                            MouseArea {
                                id: clickArea
                                anchors.fill: parent
                                onClicked: rowContainer.isExpanded = !rowContainer.isExpanded
                            }

                            // Hover/Click feedback background
                            Rectangle {
                                anchors.fill: parent
                                color: "#FFFFFF"
                                opacity: clickArea.pressed ? 0.05 : 0.0
                                radius: 8
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 0

                                // Always Visible Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 60
                                    Label { text: txDesc; color: "#FFFFFF"; font.pixelSize: 16; Layout.fillWidth: true; elide: Text.ElideRight }
                                    Label {
                                        text: (txType === "expense" ? "− " : "+ ") + txAmount
                                        color: txType === "expense" ? "#EF4444" : "#10B981"
                                        font.pixelSize: 16
                                        font.bold: true
                                    }
                                }

                                // Expanded Details Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 30
                                    visible: rowContainer.height > 60 // Hides cleanly when collapsed
                                    opacity: rowContainer.isExpanded ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }

                                    Label { text: txTime; color: "#9CA3AF"; font.pixelSize: 12; Layout.fillWidth: true }

                                    // Minimalist Delete Button (Fixed: Now clickable!)
                                    Label {
                                        text: "Delete"
                                        color: "#EF4444"
                                        font.pixelSize: 14
                                        font.bold: true
                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -10 // Make tap area larger
                                            onClicked: {
                                                cppBackend.deleteTransaction(txType, txAmount)
                                                historyModel.remove(index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Spacer to push content above the absolute bottom bar
                Item { Layout.preferredHeight: 80 }
            }

            // --- BOTTOM INPUT BAR ---
            // Fixed absolutely to the bottom
            Rectangle {
                width: parent.width - 48
                height: 60
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 24
                color: "#1C1C24"
                radius: 30 // Pill shape
                border.color: "#2A2A35"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 6

                    TextField {
                        id: aiInput
                        Layout.fillWidth: true
                        placeholderText: "Add a transaction..."
                        placeholderTextColor: "#9CA3AF"
                        color: "#FFFFFF"
                        font.pixelSize: 16
                        background: Item {} // Removes ugly default underline
                        onAccepted: sendBtnArea.clicked(null) // Enter key sends
                    }

                    // Gradient Send Button
                    Rectangle {
                        width: 48
                        height: 48
                        radius: 24
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#8B5CF6" }
                            GradientStop { position: 1.0; color: "#3B82F6" }
                        }
                        Label { text: "↑"; color: "white"; font.pixelSize: 22; font.bold: true; anchors.centerIn: parent }

                        MouseArea {
                            id: sendBtnArea
                            anchors.fill: parent
                            onClicked: {
                                if(aiInput.text !== "") {
                                    cppBackend.processInput(aiInput.text)
                                    aiInput.text = "" // Clear after sending
                                }
                            }
                            onPressed: parent.opacity = 0.8
                            onReleased: parent.opacity = 1.0
                        }
                    }
                }
            }

            // --- API KEY MODAL ---
            Popup {
                id: apiPopup
                anchors.centerIn: parent
                width: parent.width * 0.85
                modal: true
                dim: true // Automatically blurs/darkens the background

                // Fixed: Loads key from phone storage when opened
                onOpened: keyField.text = cppBackend.getApiKey()

                background: Rectangle { color: "#1C1C24"; radius: 16; border.color: "#2A2A35" }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20
                    Label { text: "API Configuration"; color: "#FFFFFF"; font.pixelSize: 18; font.bold: true }

                    TextField {
                        id: keyField
                        placeholderText: "Enter Gemini Key..."
                        placeholderTextColor: "#9CA3AF"
                        echoMode: TextInput.Password
                        Layout.fillWidth: true
                        color: "#FFFFFF"
                        background: Rectangle { color: "#0D0D12"; radius: 8; border.color: "#2A2A35"; implicitHeight: 48 }
                        leftPadding: 16
                    }

                    Button {
                        text: "Save"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        background: Rectangle { color: "#3B82F6"; radius: 8 }
                        palette.buttonText: "#FFFFFF"
                        font.bold: true
                        onClicked: {
                            // Fixed: Explicitly saves to phone storage ONLY when you click Save
                            cppBackend.setApiKey(keyField.text)
                            apiPopup.close()
                        }
                    }
                }
            }
        }
    }

    // --- ERROR DIALOG ---
    Dialog {
        id: errorDialog
        anchors.centerIn: parent
        background: Rectangle { color: "#1C1C24"; radius: 16; border.color: "#EF4444" }
        standardButtons: Dialog.Ok
        property alias text: errorLabel.text
        Label { id: errorLabel; color: "#FFFFFF"; wrapMode: Text.WordWrap; width: 250 }
    }
}