import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0

Rectangle {
    id: indicatorStripe;

    property string status : "none";

    color: Theme.highlightBackgroundColor;

    anchors.left: parent.left;
    anchors.right: parent.right;
    anchors.top: parent.top;
    height: 5;
    opacity: 0;

    onStatusChanged: {
      if (status != "insert") {
        opacity = 1;
      } else {
        opacity = 0;
      }
      if (status == "switching") {
        opacity = 0;
      }
      if (status == "normal") {
        opacity = 1;
      }
    }
}
