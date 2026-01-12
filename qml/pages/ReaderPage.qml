import QtQuick 2.0
import Sailfish.Silica 1.0
import "../lib/JSDOMParser.js" as JSDOMParser
import "../lib/Readability.js" as Readability

Page {
    id: readerPage
    property string articleUrl: ""
    property bool loading: true
    property string errorMessage: ""

    // Parsed article content
    property string articleTitle: ""
    property string articleContent: ""
    property string articleByline: ""
    property string articleSiteName: ""

    Component.onCompleted: {
        if (articleUrl) fetchArticle()
    }

    function fetchArticle() {
        loading = true
        errorMessage = ""
        console.log("ReaderPage: Fetching " + articleUrl)

        var http = new XMLHttpRequest()
        http.open("GET", articleUrl, true)
        http.setRequestHeader("User-Agent", "Mozilla/5.0 (Linux; Sailfish) Tooter/1.0")

        http.onreadystatechange = function() {
            if (http.readyState === 4) {
                console.log("ReaderPage: Got response, status=" + http.status)
                if (http.status === 200) {
                    parseArticle(http.responseText)
                } else if (http.status === 0) {
                    // CORS or network error
                    errorMessage = qsTr("Could not fetch article (network error or CORS)")
                    loading = false
                } else {
                    errorMessage = qsTr("Failed to load article (HTTP %1)").arg(http.status)
                    loading = false
                }
            }
        }

        http.onerror = function() {
            console.log("ReaderPage: XHR error")
            errorMessage = qsTr("Network error")
            loading = false
        }

        http.send()
    }

    function parseArticle(html) {
        console.log("ReaderPage: Parsing article, html length=" + html.length)
        try {
            // Use JSDOMParser to create DOM from HTML
            var parser = new JSDOMParser.JSDOMParser()
            var doc = parser.parse(html, articleUrl)
            console.log("ReaderPage: DOM parsed")

            // Use Readability to extract article
            var reader = new Readability.Readability(doc)
            var article = reader.parse()

            if (article) {
                console.log("ReaderPage: Article extracted - " + article.title)
                articleTitle = article.title || ""
                articleContent = article.content || ""
                articleByline = article.byline || ""
                articleSiteName = article.siteName || ""
            } else {
                console.log("ReaderPage: Readability returned null")
                errorMessage = qsTr("Could not extract article content")
            }
        } catch (e) {
            console.log("ReaderPage: Parse error - " + e)
            errorMessage = qsTr("Error parsing article: %1").arg(e.message || e)
        }
        loading = false
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Open in browser")
                onClicked: Qt.openUrlExternally(articleUrl)
            }
        }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingMedium

            PageHeader {
                title: articleSiteName || qsTr("Reader")
            }

            // Loading indicator
            BusyIndicator {
                visible: loading
                running: loading
                size: BusyIndicatorSize.Large
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                visible: loading
                text: qsTr("Loading article...")
                color: Theme.secondaryColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Error message
            Column {
                visible: !loading && errorMessage.length > 0
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.paddingLarge

                Label {
                    text: errorMessage
                    color: Theme.errorColor
                    wrapMode: Text.Wrap
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    text: qsTr("Open in browser instead")
                    anchors.horizontalCenter: parent.horizontalCenter
                    onClicked: {
                        Qt.openUrlExternally(articleUrl)
                        pageStack.pop()
                    }
                }
            }

            // Article title
            Label {
                visible: !loading && articleTitle.length > 0
                text: articleTitle
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                color: Theme.highlightColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Byline
            Label {
                visible: !loading && articleByline.length > 0
                text: articleByline
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Separator
            Separator {
                visible: !loading && articleTitle.length > 0
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.primaryColor
                horizontalAlignment: Qt.AlignHCenter
            }

            // Article content
            Label {
                visible: !loading && articleContent.length > 0
                text: articleContent
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
                wrapMode: Text.Wrap
                textFormat: Text.RichText
                width: parent.width - Theme.horizontalPageMargin * 2
                anchors.horizontalCenter: parent.horizontalCenter
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }

        VerticalScrollDecorator {}
    }
}
