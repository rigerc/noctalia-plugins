import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root

    property string title: ""
    property string description: ""
    property string icon: ""
    property var navigationSections: []
    property string activeSectionId: ""
    default property alias content: contentColumn.data

    Layout.fillWidth: true
    spacing: Style.marginXL

    function _sectionY(section) {
        if (!section || !section.target || !contentColumn)
            return 0;
        return Math.max(0, section.target.mapToItem(contentColumn, 0, 0).y);
    }

    function _resolvedSections() {
        if (!Array.isArray(root.navigationSections))
            return [];
        return root.navigationSections.filter(function (section) {
            return !!section && !!section.id && !!section.target;
        });
    }

	    function jumpToSection(sectionId) {
	        var sections = root._resolvedSections();
	        for (var i = 0; i < sections.length; i++) {
	            var section = sections[i];
	            if (section.id !== sectionId)
	                continue;
	            if (pageScroll.contentItem)
	                pageScroll.contentItem.contentY = pageScroll.clampScrollY(root._sectionY(section));
	            root.activeSectionId = section.id;
	            break;
	        }
	    }

    function _updateActiveSection() {
        var sections = root._resolvedSections();
        if (sections.length === 0) {
            root.activeSectionId = "";
            return;
        }

	        var currentY = pageScroll.contentItem ? pageScroll.contentItem.contentY : 0;
	        var bestSection = sections[0];
	        for (var i = 0; i < sections.length; i++) {
	            var section = sections[i];
	            if (root._sectionY(section) <= currentY + Style.marginM)
                bestSection = section;
        }
        root.activeSectionId = bestSection.id;
    }

    NLabel {
        Layout.fillWidth: true
        label: root.title
        description: root.description
        icon: root.icon
        labelSize: Style.fontSizeXL
        iconColor: Color.mPrimary
    }

    NDivider {
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginM
    }

    Flow {
        visible: root._resolvedSections().length > 0
        Layout.fillWidth: true
        Layout.bottomMargin: Style.marginL
        spacing: Style.marginS

        Repeater {
            model: root._resolvedSections()

            delegate: NButton {
                required property var modelData

                text: modelData.label || ""
                icon: modelData.icon || ""
                fontSize: Style.fontSizeS
                outlined: root.activeSectionId !== modelData.id
                backgroundColor: Color.mPrimary
                textColor: Color.mOnPrimary
                hoverColor: root.activeSectionId === modelData.id ? Color.mPrimary : Color.mHover
                textHoverColor: root.activeSectionId === modelData.id ? Color.mOnPrimary : Color.mOnHover
                onClicked: root.jumpToSection(modelData.id)
            }
        }
    }

    NScrollView {
        id: pageScroll

        Layout.fillWidth: true
        Layout.preferredHeight: 560 * Style.uiScaleRatio
        horizontalPolicy: ScrollBar.AlwaysOff
        showGradientMasks: true

        ColumnLayout {
            id: contentColumn

            width: pageScroll.availableWidth
            spacing: Style.marginXL
        }
	    }

	    Connections {
	        target: pageScroll.contentItem

        function onContentYChanged() {
            root._updateActiveSection();
	    }
    }

    Component.onCompleted: root._updateActiveSection()
    onNavigationSectionsChanged: root._updateActiveSection()
}
