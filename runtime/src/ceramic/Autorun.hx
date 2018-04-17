package ceramic;

import ceramic.Shortcuts.*;

class Autorun extends Entity {

/// Current autorun

    static var prevCurrent:Array<Autorun> = [];

    public static var current:Autorun = null;

/// Events

    @event function reset();

/// Properties

    var onRun:Void->Void;

    var invalidated(default,null):Bool = false;

/// Lifecycle

    public function new(onRun:Void->Void) {

        this.onRun = onRun;

        // Run once to create initial binding and execute callback
        run();

    } //new

    public function run():Void {

        // Nothing to do if destroyed
        if (destroyed) return;

        // We are not invalidated anymore as we are resetting state
        invalidated = false;

        // Unbind everything
        emitReset();

        // Set current autorun to self
        var prevCurrent = current;
        current = this;

        // Run (and bind) again
        onRun();

        // Restore previous current autorun
        current = prevCurrent;

    } //run

    inline public function invalidate():Void {

        if (invalidated) return;
        invalidated = true;

        app.onceImmediate(run);

    } //invalidate

/// Static helpers

    /** Ensures current `autorun` won't be affected by the code after this call.
        `reobserve()` should be called to restore previous state. */
    inline public static function unobserve():Void {

        // Set current autorun to null
        prevCurrent.push(current);
        current = null;

    } //unobserve

    /** Resume observing values and resume affecting current `autorun` scope.
        This should be called after an `unobserve()` call. */
    inline public static function reobserve():Void {

        Assert.assert(prevCurrent.length > 0, 'Cannot call reobserve() without calling observe() before.');

        // Restore previous current autorun
        current = prevCurrent.pop();

    } //reobserve

    /** Executes the given function synchronously and ensures the
        current `autorun` scope won't be affected */
    public static function unobserved(func:Void->Void):Void {

        unobserve();
        func();
        reobserve();

    } //unobserved

} //Autorun
