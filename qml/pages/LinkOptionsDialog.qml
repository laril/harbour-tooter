import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: linkOptionsPage
    property string url: ""
    property bool openInReader: false

    signal optionSelected(bool useReader)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                title: qsTr("Open Link")
            }

            // URL display
            Label {
                text: url
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
                maximumLineCount: 3
                truncationMode: TruncationMode.Fade
            }

            // Spacing
            Item { width: 1; height: Theme.paddingLarge }

            // Reader Mode button
            Button {
                text: qsTr("Reader Mode")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("ReaderPage.qml"), {
                        articleUrl: url
                    })
                }
            }

            // Open in Browser button
            Button {
                text: qsTr("Open in Browser")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Qt.openUrlExternally(url)
                    pageStack.pop()
                }
            }

            // Copy link button
            Button {
                text: qsTr("Copy Link")
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    Clipboard.text = url
                    pageStack.pop()
                }
            }
        }
    }
}
