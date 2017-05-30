package ceramic.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import sys.FileSystem;

using StringTools;

class AssetsMacro {

    static var backendInfo:backend.Info = null;

    static var allAssets:Array<String> = null;

    static var assetsByBaseName:Map<String,Array<String>> = null;

    static var reAsciiChar = ~/^[a-zA-Z0-9]$/;

    macro static public function buildNames(kind:String):Array<Field> {
        
        initData(Context.definedValue('assets_path'), Context.definedValue('ceramic_assets_path'));

        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        var extensions = switch (kind) {
            case 'image': backendInfo.imageExtensions();
            case 'text': backendInfo.textExtensions();
            case 'sound': backendInfo.soundExtensions();
            case 'font': ['fnt'];
            default: [];
        }

        if (extensions.length == 0) return fields;

        var used = new Map<String,String>();

        for (ext in extensions) {

            for (name in allAssets) {

                var lowerName = name.toLowerCase();
                var dotIndex = lowerName.lastIndexOf('.');
                var fileExt = null;
                var baseName = null;
                var fieldName = null;

                if (dotIndex != -1) {
                    fileExt = lowerName.substr(dotIndex + 1);

                    if (fileExt == ext) {

                        var truncatedName = name.substr(0, dotIndex);
                        var baseAtIndex = truncatedName.lastIndexOf('@');
                        if (baseAtIndex == -1) baseAtIndex = dotIndex;

                        baseName = name.substr(0, cast Math.min(baseAtIndex, dotIndex));
                        fieldName = toAssetConstName(baseName);
                    
                        if (fieldName != null && !used.exists(fieldName) && fileExt != null) {
                            used.set(fieldName, baseName);
                        }
                    }
                }
            }
        }

        // Add fields
        for (fieldName in used.keys()) {
            var value = kind + ':' + used.get(fieldName);

            var expr = { expr: ECast({ expr: EConst(CString(value)), pos: pos }, null), pos: pos };
            
            var fieldDoc = [];
            var files = assetsByBaseName.get(used.get(fieldName));
            for (file in files) {
                for (ext in extensions) {
                    if (file.endsWith('.$ext')) {
                        fieldDoc.push(file);
                        break;
                    }
                }
            }

            var field = {
                pos: pos,
                name: fieldName,
                kind: FProp('default', 'null', macro :ceramic.Assets.AssetId, expr),
                access: [AStatic, APublic],
                doc: fieldDoc.join(', '),
                meta: []
            };

            fields.push(field);
        }

        return fields;

    } //build

    macro static public function buildLists():Array<Field> {
        
        initData(Context.definedValue('assets_path'), Context.definedValue('ceramic_assets_path'));

        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        // All assets
        //
        var exprEntries = [];
        
        for (name in allAssets) {
            exprEntries.push({expr: EConst(CString(name)), pos: pos});
        }

        var expr = {expr: EArrayDecl(exprEntries), pos: pos};

        var field = {
            pos: pos,
            name: 'all',
            kind: FProp('default', 'null', macro :Array<String>, expr),
            access: [AStatic, APublic],
            doc: 'All asset paths array',
            meta: []
        };

        fields.push(field);

        // Assets by base name
        //
        var exprEntries = [];

        for (baseName in assetsByBaseName.keys()) {
            var list = assetsByBaseName.get(baseName);
            var listExprs = [];

            for (entry in list) {
                listExprs.push({expr: EConst(CString(entry)), pos: pos});
            }

            exprEntries.push({expr: EBinop(OpArrow, {expr: EConst(CString(baseName)), pos: pos}, {expr: EArrayDecl(listExprs), pos: pos}), pos: pos});
        }

        var expr = {expr: EArrayDecl(exprEntries), pos: pos};

        var field = {
            pos: pos,
            name: 'allByName',
            kind: FProp('default', 'null', macro :Map<String,Array<String>>, expr),
            access: [AStatic, APublic],
            doc: 'Assets by base name',
            meta: []
        };

        fields.push(field);

        return fields;

    } //buildLists

    static function initData(assetsPath:String, ceramicAssetsPath:String):Void {

        if (backendInfo == null) backendInfo = new backend.Info();

        if (allAssets == null) {

            var usedPaths:Map<String,Bool> = new Map();

            if (FileSystem.exists(assetsPath)) {
                allAssets = getFlatDirectory(assetsPath);
            } else {
                allAssets = [];
            }

            for (asset in allAssets) {
                usedPaths.set(asset, true);
            }

            if (FileSystem.exists(ceramicAssetsPath)) {
                for (asset in getFlatDirectory(ceramicAssetsPath)) {
                    if (!usedPaths.exists(asset)) {
                        allAssets.push(asset);
                    }
                }
            }
        }

        if (assetsByBaseName == null) {

            assetsByBaseName = new Map();

            for (name in allAssets) {
                var dotIndex = name.lastIndexOf('.');
                var truncatedName = name.substr(0, dotIndex);
                var baseAtIndex = truncatedName.lastIndexOf('@');
                if (baseAtIndex == -1) baseAtIndex = dotIndex;

                var baseName = name.substr(0, cast Math.min(baseAtIndex, dotIndex));
                if (!assetsByBaseName.exists(baseName)) {
                    assetsByBaseName.set(baseName, []);
                }
                var list = assetsByBaseName.get(baseName);
                list.push(name);
            }
        }

    } //initData

    static function toAssetConstName(input:String):String {

        var res = new StringBuf();
        var len = input.length;
        var i = 0;
        var canAddSpace = false;

        while (i < len) {

            var c = input.charAt(i);
            if (c == '/') {
                res.add('__');
                canAddSpace = false;
            }
            else if (c == '.') {
                res.add('_');
                canAddSpace = false;
            }
            else if (reAsciiChar.match(c)) {

                var uc = c.toUpperCase();
                var isUpperCase = (c == uc);

                if (canAddSpace && isUpperCase) {
                    res.add('_');
                    canAddSpace = false;
                }

                res.add(uc);
                canAddSpace = !isUpperCase;
            }
            else {
                res.add('_');
                canAddSpace = false;
            }

            i++;
        }

        var str = res.toString();
        if (str.endsWith('_')) str = str.substr(0, str.length - 1);

        return str;

    } //toAssetConstName
    
    static function getFlatDirectory(dir:String, excludeSystemFiles:Bool = true, subCall:Bool = false):Array<String> {

        var result:Array<String> = [];

        for (name in FileSystem.readDirectory(dir)) {

            if (excludeSystemFiles && name == '.DS_Store') continue;

            var path = Path.join([dir, name]);
            if (FileSystem.isDirectory(path)) {
                result = result.concat(getFlatDirectory(path, excludeSystemFiles, true));
            } else {
                result.push(path);
            }
        }

        if (!subCall) {
            var prevResult = result;
            result = [];
            var prefix = Path.normalize(dir);
            if (!prefix.endsWith('/')) prefix += '/';
            for (item in prevResult) {
                result.push(item.substr(prefix.length));
            }
        }

        return result;

    } //getFlatDirectory

}