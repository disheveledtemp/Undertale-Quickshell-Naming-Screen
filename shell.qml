import QtQuick
import QtQuick.Layouts 
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: root

    property bool playAudio: true

    Process {
        id: bgm
        command: [
            "ffplay", 
            "-nodisp",          // Don't open a video window
            "-loop", "0",        // Loop indefinitely
            "-autoexit",
            String(Qt.resolvedUrl("startmenu.wav")).replace("file://", "")
        ]
        running: root.playAudio
    }

    Component.onDestruction: bgm.running = false

// Wayland layer shell overlay configuration
    WlrLayershell.namespace: "undertale-namescreen"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.Exclusive
    exclusionMode: ExclusionMode.Ignore

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

// Enable direct keyboard typing vs. grid navigation
    property bool allowDirectKeyboard: true

// Exports the chosen name when "Yes" is confirmed
    signal nameConfirmed(string name)
    property string confirmedName: ""

// Internal state
    property string nameText: ""
    property bool isConfirming: false
    property bool isTransitioning: false
    property int selectedRow: 0
    property int selectedCol: 0
    property int preferredCol: 0
    property int confirmChoice: 1
    property real nameJitterX: 0
    property real nameJitterY: 0

    readonly property string upAlpha: "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    readonly property string loAlpha: "abcdefghijklmnopqrstuvwxyz"

    FontLoader { id: uFont; source: "DeterminationMono.otf" }

// Text jitter timer for confirmation and zoom states
    Timer { 
        interval: 16
        running: root.isConfirming || root.isTransitioning
        repeat: true
        onTriggered: { 
            root.nameJitterX = (Math.random() - 0.5) * 8
            root.nameJitterY = (Math.random() - 0.5) * 8 
        } 
    }

// Clamp column index based on row boundaries (menu row has 3 items, letter rows have up to 7)
    function updateSelectedCol() { 
        root.selectedCol = Math.min((root.selectedRow === 3 || root.selectedRow === 7) ? 4 : (root.selectedRow === 8 ? 2 : 6), root.preferredCol) 
    }

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: "black"
        focus: true

        Component.onCompleted: mainContainer.forceActiveFocus()

        Keys.onPressed: (e) => {
// Mode enforcement for physical input
            if (!root.allowDirectKeyboard) {
                if (e.key === Qt.Key_Escape || e.key === Qt.Key_Backspace || e.key === Qt.Key_Space) { 
                    e.accepted = true
                    return 
                }
            } else if (e.key === Qt.Key_Escape) { 
                root.isConfirming ? root.isConfirming = false : Qt.quit()
                e.accepted = true
                return 
            }

// Confirmation screen input
            if (root.isConfirming) {
                if (e.key === Qt.Key_Left || e.key === Qt.Key_Right) {
                    root.confirmChoice = 1 - root.confirmChoice
                } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                    if (root.confirmChoice === 1) {
                        root.confirmedName = root.nameText

// You can change this to do something.
                        console.log("[Undertale NameScreen] Confirmed name:", root.nameText)
                        root.nameConfirmed(root.nameText)

                        Qt.quit()
                    } else {
                        root.isConfirming = false
                    }
                }
                e.accepted = true
                return
            }

// Keyboard Typing
            if (root.allowDirectKeyboard) {
                if (e.key === Qt.Key_Backspace) { 
                    root.nameText = root.nameText.slice(0, -1)
                    e.accepted = true
                    return 
                }
                if (e.text.length === 1 && !e.isAutoRepeat && /[a-zA-Z]/.test(e.text) && root.nameText.length < 6) { 
                    root.nameText += e.text
                    e.accepted = true
                    return 
                }
            }

// On-screen grid navigation
            if (e.key === Qt.Key_Left) root.preferredCol = Math.max(0, root.preferredCol - 1)
            else if (e.key === Qt.Key_Right) root.preferredCol = Math.min(6, root.preferredCol + 1)
            else if (e.key === Qt.Key_Up) root.selectedRow = root.selectedRow === 8 ? 7 : Math.max(0, root.selectedRow - 1)
            else if (e.key === Qt.Key_Down) root.selectedRow = Math.min(8, root.selectedRow + 1)
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (root.selectedRow < 4) {
                    let i = root.selectedRow * 7 + root.selectedCol
                    if (i < root.upAlpha.length && root.nameText.length < 6) root.nameText += root.upAlpha[i]
                } else if (root.selectedRow < 8) {
                    let i = (root.selectedRow - 4) * 7 + root.selectedCol
                    if (i < root.loAlpha.length && root.nameText.length < 6) root.nameText += root.loAlpha[i]
                } else {
                    if (root.selectedCol === 0) Qt.quit()
                    else if (root.selectedCol === 1 && root.nameText.length > 0) root.nameText = root.nameText.slice(0, -1)
                    else if (root.selectedCol === 2 && root.nameText.length > 0) {
                        root.isConfirming = true
                        root.confirmChoice = 1
                    }
                }
            }
            root.updateSelectedCol()
            e.accepted = true
        }

        // 7-column grid layout for alphabet rendering
        component LetterGrid: GridLayout {
            property string alphabet
            property int startRow
            columns: 7
            rowSpacing: 40
            columnSpacing: 130
            Layout.alignment: Qt.AlignHCenter
            
            Repeater {
                model: alphabet.split("")
                Item {
                    id: lItem
                    required property string modelData
                    required property int index
                    readonly property bool sel: root.selectedRow === (Math.floor(index / 7) + startRow) && root.selectedCol === (index % 7)
                    property real jX: 0
                    property real jY: 0
                    width: 24
                    height: 24

                    Timer { 
                        interval: 50
                        running: !root.isConfirming
                        repeat: true
                        onTriggered: { 
                            lItem.jX = (Math.random() - 0.5) * 2
                            lItem.jY = (Math.random() - 0.5) * 2 
                        } 
                    }

                    Text {
                        text: modelData
                        color: sel ? "yellow" : "white"
                        font.pixelSize: 60
                        font.family: uFont.name
                        anchors.centerIn: parent
                        transform: Translate { x: lItem.jX; y: lItem.jY }
                    }
                }
            }
        }

        component MenuBtn: Text {
            property int cIdx
            property bool cond: true
            color: root.selectedRow === 8 && root.selectedCol === cIdx ? "yellow" : (cond ? "white" : "gray")
            font.pixelSize: 60
            font.family: uFont.name
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Item {
                implicitWidth: 500
                implicitHeight: 60
                Layout.alignment: Qt.AlignHCenter
                Text {
                    anchors.centerIn: parent
                    text: root.isConfirming ? "Is this name correct?" : "Name the fallen human."
                    color: "white"
                    font.pixelSize: 60
                    font.family: uFont.name
                    transform: Translate { y: -150 }
                }
            }

            Item {
                implicitWidth: nameDisp.implicitWidth
                implicitHeight: 70
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 10
                
                Text {
                    id: nameDisp
                    text: root.nameText
                    color: "white"
                    font.pixelSize: 60
                    font.family: uFont.name
                    anchors.centerIn: parent
                    property real baseX: 0
                    property real baseY: -110
                    
                    transform: Translate { 
                        x: nameDisp.baseX + ((root.isConfirming || root.isTransitioning) ? root.nameJitterX : 0)
                        y: nameDisp.baseY + ((root.isConfirming || root.isTransitioning) ? root.nameJitterY : 0) 
                    }
                    
                    states: State {
                        name: "confirming"
                        when: root.isConfirming
                        PropertyChanges { target: nameDisp; scale: 3.0; baseX: 0; baseY: 250 }
                    }
                    
                    transitions: [
                        Transition {
                            from: ""
                            to: "confirming"
                            ParallelAnimation {
                                ScriptAction { script: root.isTransitioning = true }
                                NumberAnimation { targets: [nameDisp]; properties: "scale,baseX,baseY"; duration: 6000; easing.type: Easing.OutCubic }
                                ScriptAction { script: root.isTransitioning = false }
                            }
                        },
                        Transition {
                            from: "confirming"
                            to: ""
                            ScriptAction { script: { root.isTransitioning = false; root.nameJitterX = 0; root.nameJitterY = 0 } }
                        }
                    ]
                }
            }

            Item {
                implicitWidth: 600
                implicitHeight: 380
                Layout.alignment: Qt.AlignHCenter

                ColumnLayout {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 16
                    visible: !root.isConfirming
                    
                    ColumnLayout {
                        spacing: 16
                        Layout.alignment: Qt.AlignHCenter
                        transform: Translate { y: -70 }
                        LetterGrid { alphabet: root.upAlpha; startRow: 0 }
                        Item { implicitHeight: 20 }
                        LetterGrid { alphabet: root.loAlpha; startRow: 4 }
                    }
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 150
                        transform: Translate { y: -30 }
                        MenuBtn { text: "Quit"; cIdx: 0 }
                        MenuBtn { text: "Backspace"; cIdx: 1 }
                        MenuBtn { text: "Done"; cIdx: 2; cond: root.nameText.length > 0 }
                    }
                }

                Item {
                    anchors.centerIn: parent
                    implicitHeight: 180
                    implicitWidth: 300
                    visible: root.isConfirming
                    
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 560
                        transform: Translate { y: 310 }
                        Text { text: "No"; color: root.confirmChoice === 0 ? "yellow" : "white"; font.pixelSize: 60; font.family: uFont.name }
                        Text { text: "Yes"; color: root.confirmChoice === 1 ? "yellow" : "white"; font.pixelSize: 60; font.family: uFont.name }
                    }
                }
            }
        }
    }
}