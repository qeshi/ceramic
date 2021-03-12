package ceramic;

import ceramic.Shortcuts.*;

class ConvertFont implements ConvertField<String,BitmapFont> {

    public function new() {}

    public function basicToField(instance:Entity, assets:Assets, basic:String, done:BitmapFont->Void):Void {

        if (basic != null) {
            if (basic == app.defaultFont.asset.name) {
                done(app.defaultFont);
            }
            else {
                assets.ensureFont(basic, null, function(asset:FontAsset) {
                    done(asset != null ? asset.font : null);
                });
            }
        }
        else {
            done(null);
        }

    }

    public function fieldToBasic(instance:Entity, value:BitmapFont):String {

        return (value == null || value.asset == null) ? null : value.asset.name;

    }

}
