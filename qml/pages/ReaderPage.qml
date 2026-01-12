import QtQuick 2.0
import Sailfish.Silica 1.0

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
                    parseArticleSimple(http.responseText)
                } else if (http.status === 0) {
                    errorMessage = qsTr("Could not fetch article (network error)")
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

    // Simple HTML to readable text extraction (fallback approach)
    function parseArticleSimple(html) {
        console.log("ReaderPage: Parsing article, html length=" + html.length)
        try {
            // Extract title from <title> tag
            var titleMatch = html.match(/<title[^>]*>([^<]+)<\/title>/i)
            if (titleMatch) {
                articleTitle = titleMatch[1].replace(/\s+/g, ' ').trim()
            }

            // Try to get og:site_name
            var siteMatch = html.match(/<meta[^>]+property=["']og:site_name["'][^>]+content=["']([^"']+)["']/i)
            if (!siteMatch) {
                siteMatch = html.match(/<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:site_name["']/i)
            }
            if (siteMatch) {
                articleSiteName = siteMatch[1]
            }

            // Try to get article content - look for <article> or <main> or common content divs
            var content = html

            // Remove scripts, styles, nav, header, footer, aside
            content = content.replace(/<script[^>]*>[\s\S]*?<\/script>/gi, '')
            content = content.replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
            content = content.replace(/<nav[^>]*>[\s\S]*?<\/nav>/gi, '')
            content = content.replace(/<header[^>]*>[\s\S]*?<\/header>/gi, '')
            content = content.replace(/<footer[^>]*>[\s\S]*?<\/footer>/gi, '')
            content = content.replace(/<aside[^>]*>[\s\S]*?<\/aside>/gi, '')
            content = content.replace(/<form[^>]*>[\s\S]*?<\/form>/gi, '')
            content = content.replace(/<iframe[^>]*>[\s\S]*?<\/iframe>/gi, '')

            // Try to extract just the article or main content
            var articleMatch = content.match(/<article[^>]*>([\s\S]*?)<\/article>/i)
            if (articleMatch) {
                content = articleMatch[1]
            } else {
                var mainMatch = content.match(/<main[^>]*>([\s\S]*?)<\/main>/i)
                if (mainMatch) {
                    content = mainMatch[1]
                } else {
                    // Look for common content class names
                    var contentMatch = content.match(/<div[^>]+class=["'][^"']*(?:content|article|post|entry|story)[^"']*["'][^>]*>([\s\S]*?)<\/div>/i)
                    if (contentMatch) {
                        content = contentMatch[1]
                    }
                }
            }

            // Convert block elements to preserve structure
            content = content.replace(/<\/p>/gi, '\n\n')
            content = content.replace(/<\/div>/gi, '\n')
            content = content.replace(/<\/h[1-6]>/gi, '\n\n')
            content = content.replace(/<br\s*\/?>/gi, '\n')
            content = content.replace(/<li>/gi, '• ')
            content = content.replace(/<\/li>/gi, '\n')

            // Remove remaining HTML tags
            content = content.replace(/<[^>]+>/g, '')

            // Decode HTML entities
            content = content.replace(/&nbsp;/g, ' ')
            content = content.replace(/&amp;/g, '&')
            content = content.replace(/&lt;/g, '<')
            content = content.replace(/&gt;/g, '>')
            content = content.replace(/&quot;/g, '"')
            content = content.replace(/&#39;/g, "'")

            // Clean up whitespace
            content = content.replace(/[ \t]+/g, ' ')
            content = content.replace(/\n\s*\n\s*\n/g, '\n\n')
            content = content.trim()

            if (content.length > 100) {
                articleContent = content
                console.log("ReaderPage: Extracted " + content.length + " chars")
            } else {
                errorMessage = qsTr("Could not extract article content")
            }
        } catch (e) {
            console.log("ReaderPage: Parse error - " + e)
            errorMessage = qsTr("Error parsing article")
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
                x: Theme.horizontalPageMargin
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
                x: Theme.horizontalPageMargin
            }

            // Separator
            Separator {
                visible: !loading && articleTitle.length > 0
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
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
                width: parent.width - Theme.horizontalPageMargin * 2
                x: Theme.horizontalPageMargin
            }
        }

        VerticalScrollDecorator {}
    }
}
