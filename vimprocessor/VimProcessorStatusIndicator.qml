import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0 as Silica

Rectangle {
    id: indicatorStripe;

    property string status : "none";
    property color switchingColor : "pink";
    property color normalColor : "blue";

    color: "pink";

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
        color = switchingColor;
      }
      if (status == "normal") {
        color = normalColor;
      }
      MInputMethodQuick.sendCommit("istatus: " + status + "\n");
      MInputMethodQuick.sendCommit("icolor: " + color + "\n");
    }
}
