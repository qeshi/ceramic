package backend;

import unityengine.inputsystem.Mouse;

class Screen implements tracker.Events #if !completion implements spec.Screen #end {

    public function new() {
        
        width = untyped __cs__('UnityEngine.Screen.width');
        height = untyped __cs__('UnityEngine.Screen.height');
        
    }

    var width:Int = 0;

    var height:Int = 0;

/// Events

    @event function resize();

    @event function mouseDown(buttonId:Int, x:Float, y:Float);
    @event function mouseUp(buttonId:Int, x:Float, y:Float);
    @event function mouseWheel(x:Float, y:Float);
    @event function mouseMove(x:Float, y:Float);

    @event function touchDown(touchIndex:Int, x:Float, y:Float);
    @event function touchUp(touchIndex:Int, x:Float, y:Float);
    @event function touchMove(touchIndex:Int, x:Float, y:Float);

/// Public API

    inline public function getWidth():Int {

        return width;

    }

    inline public function getHeight():Int {

        return height;

    }

    inline public function getDensity():Float {

        return 1.0; // TODO retrieve native screen density

    }

    public function setBackground(background:Int):Void {

        // Background will be updated when drawing

    }

    public function setWindowTitle(title:String):Void {

        // TODO

    }

/// Internal

    @:allow(backend.Backend)
    function update() {

        var newWidth = untyped __cs__('UnityEngine.Screen.width');
        var newHeight = untyped __cs__('UnityEngine.Screen.height');

        var didResize = (width != newWidth) || (height != newHeight);

        width = newWidth;
        height = newHeight;

        if (didResize) {
            emitResize();
        }

        updateMouseInput();

    }

/// Mouse input

    var mouseLeftPressed:Bool = false;

    var mouseMiddlePressed:Bool = false;

    var mouseRightPressed:Bool = false;

    var mouseX:Float = -1;

    var mouseY:Float = -1;

    function updateMouseInput() {

        var mouse = Mouse.current;

        var newMouseX = mouse.position.x.ReadValue();
        var newMouseY = height - mouse.position.y.ReadValue();

        // Use a factor to try to get a consistent value with other targets
        var mouseScrollX = Math.floor(mouse.scroll.x.ReadValue());
        var mouseScrollY = Math.floor(mouse.scroll.y.ReadValue());

        if (mouseScrollX != 0 || mouseScrollY != 0) {
            emitMouseWheel(mouseScrollX, mouseScrollY);
        }

        if (newMouseX != mouseX || newMouseY != mouseY) {
            mouseX = newMouseX;
            mouseY = newMouseY;
            emitMouseMove(mouseX, mouseY);
        }

        if (mouse.leftButton.isPressed) {
            if (!mouseLeftPressed) {
                mouseLeftPressed = true;
                emitMouseDown(1, mouseX, mouseY);
            }
        }
        else {
            if (mouseLeftPressed) {
                mouseLeftPressed = false;
                emitMouseUp(1, mouseX, mouseY);
            }
        }

        if (mouse.middleButton.isPressed) {
            if (!mouseMiddlePressed) {
                mouseMiddlePressed = true;
                emitMouseDown(2, mouseX, mouseY);
            }
        }
        else {
            if (mouseMiddlePressed) {
                mouseMiddlePressed = false;
                emitMouseUp(2, mouseX, mouseY);
            }
        }

        if (mouse.rightButton.isPressed) {
            if (!mouseRightPressed) {
                mouseRightPressed = true;
                emitMouseDown(3, mouseX, mouseY);
            }
        }
        else {
            if (mouseRightPressed) {
                mouseRightPressed = false;
                emitMouseUp(3, mouseX, mouseY);
            }
        }

    }

}
