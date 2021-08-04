package ceramic;

import tracker.Observable;
import ceramic.Shortcuts.*;

#if (!macro && !completion)
@:autoBuild(ceramic.macros.SceneMacro.build())
#end
@:allow(ceramic.SceneSystem)
class Scene extends Layer implements Observable {

    var _assets:Assets = null;

    var didCreate:Bool = false;

    @observe var transitionStatus:SceneTransitionStatus = NONE;

    public var assets(get, set):Assets;
    function get_assets():Assets {
        if (_assets == null && !destroyed) {
            _assets = new Assets();
        }
        return _assets;
    }
    function set_assets(assets:Assets):Assets {
        return _assets = assets;
    }

    /**
     * Set to `false` if you want to disable auto update on this scene object.
     * If auto update is disabled, you become responsible to explicitly call
     * `update(delta)` at every frame yourself. Use this if you want to have control over
     * when the animation update is actually happening. Don't use it to pause animation.
     * (animation can be paused with `paused` property instead)
     */
    public var autoUpdate:Bool = true;

    /**
     * Is this scene paused?
     */
    public var paused:Bool = false;

    public function new() {

        super();

        transparent = true;

        SceneSystem.shared.all.original.push(cast this);

    }

    function _boot() {

        preload();

        if (_assets != null && _assets.hasAnythingToLoad()) {
            // If assets have been added, load them
            _assets.onceComplete(this, _handleAssetsComplete);
            _assets.load();
        }
        else {
            // No asset, can call load() directly
            load(internalCreate);
        }

    }

    function internalCreate() {

        create();
        didCreate = true;

        fadeIn(_markReady);

    }

    function _markReady():Void {

        transitionStatus = READY;

    }

    function _handleAssetsComplete(successful:Bool):Void {

        if (successful) {
            load(internalCreate);
        }
        else {
            log.error('Failed to load all scene assets!');
        }

    }

    override function willEmitResize(width:Float, height:Float):Void {

        resize(width, height);

    }

/// Lifecycle

    /**
     * Override this method to configure the scene, add assets to it...
     * example: `assets.add(Images.SOME_IMAGE);`
     * Added assets will be loaded automatically
     */
    function preload():Void {

        // Override in subclasses

    }

    /**
     * Override this method to perform any additional asynchronous loading.
     * `next()` must be called once the loading has finished so that the scene
     * can continue its createialization process.
     * @param next The callback to call once asynchronous loading is done 
     */
    function load(next:()->Void):Void {

        // Override in subclasses

        // Default: there is nothing asynchronous to load, just call next()
        next();

    }

    /**
     * Called once the scene has finished its loading.
     * At this point, and after `create()`, `update(delta)` will be called at every frame until the scene gets destroyed
     */
    function create():Void {

        // Override in subclasses

    }

    /**
     * Called at every frame, but only after create() has been called and when the scene is not paused
     * @param delta 
     */
    public function update(delta:Float):Void {

        // Override in subclasses

    }

    /**
     * Called if the scene size has been changed during this frame.
     * @param width new width
     * @param height new height
     */
    public function resize(width:Float, height:Float):Void {

        // Override in subclasses

    }

    @:noCompletion function _fadeIn(done:()->Void):Void {

        done();

    }

    @:noCompletion function _fadeOut(done:()->Void):Void {

        done();

    }

    /**
     * Play **fade-in** transition of this scene. This is automatically called right after
     * the scene is ready to use, meaning after `create()` has been called.
     * Default implementation does nothing and calls `done()` right away.
     * Override in subclasses to perform custom transitions.
     * @param done Called when the fade-in transition has finished.
     */
    public function fadeIn(done:()->Void):Void {

        transitionStatus = FADE_IN;
        _fadeIn(() -> {
            transitionStatus = READY;
            done();
        });

    }

    /**
     * Play **fade-out** transition of this scene. This is called manually on secondary scene
     * but will be called automatically if the scene is the **main scene** and is replaced
     * by a new scene or simply removed.
     * @param done Called when the fade-out transition has finished.
     */
    public function fadeOut(done:()->Void):Void {

        transitionStatus = FADE_OUT;
        _fadeOut(() -> {
            transitionStatus = DISABLED;
            done();
        });

    }

    public function scheduleOnceReady(owner:Entity, callback:()->Void):Bool {

        if (destroyed) {
            log.warning('Cannot schedule callback on destroyed scene');
            return false;
        }

        switch transitionStatus {

            case NONE | FADE_IN:
                onceTransitionStatusChange(owner, function(_, _) {
                    scheduleOnceReady(owner, callback);
                });
                return true;

            case READY:
                callback();
                return true;

            case FADE_OUT | DISABLED:
                log.warning('Cannot schedule callback on scene with transition status: $transitionStatus');
                return false;
        }

    }

    override function destroy() {

        SceneSystem.shared.all.original.remove(cast this);

        if (_assets != null) {
            _assets.destroy();
            _assets = null;
        }

        super.destroy();

    }

}