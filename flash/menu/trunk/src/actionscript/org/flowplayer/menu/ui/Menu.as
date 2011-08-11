/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <api@iki.fi>
 *
 * Copyright (c) 2008-2011 Flowplayer Oy
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.menu.ui {
    import flash.display.DisplayObject;
    import flash.display.DisplayObject;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filters.DropShadowFilter;

    import org.flowplayer.config.Config;
    import org.flowplayer.config.ConfigParser;
    import org.flowplayer.controller.ResourceLoader;
    import org.flowplayer.flow_internal;

    import org.flowplayer.menu.*;
    import org.flowplayer.model.DisplayPluginModel;
    import org.flowplayer.model.DisplayProperties;
    import org.flowplayer.model.Plugin;
    import org.flowplayer.model.PluginEvent;
    import org.flowplayer.model.PluginModel;
    import org.flowplayer.ui.containers.WidgetContainer;
    import org.flowplayer.ui.containers.WidgetContainerEvent;
    import org.flowplayer.ui.dock.Dock;
    import org.flowplayer.ui.dock.DockConfig;
    import org.flowplayer.util.PropertyBinder;
    import org.flowplayer.view.AbstractSprite;
    import org.flowplayer.view.Flowplayer;
    import org.flowplayer.view.Styleable;

    use namespace flow_internal;

    public class Menu extends AbstractSprite implements Plugin, Styleable {
        private var _config:MenuConfig;
        private var _dock:Dock;
        private var _player:Flowplayer;
        private var _name:String;
        private var _menuButtonController:MenuButtonController;
        private var _menuButtonContainer:WidgetContainer;
        private var _model:PluginModel;

        /**
         * Adds menu items.
         *
         * @param items an array of MenuConfig instances or objects with properties for MenuConfig instances
         * @return the new menu length
         */
        [External]
        public function addItems(items:Array):int {
            createItems(_config.setItems(items));
            updateModelHeight();
            if (_menuButtonContainer && model.visible) {
                adjustDockPosition();
            }
            return _config.items.length;
        }

        /**
         * Adds an item to the menu.
         *
         * @param itemConf and Object with with properties for a ItemConfig object. Or an instance of ItemConfig.
         * @param should the menu be moved if the menu's height changes as a result of removing items
         * @return the index of the item the item in the menu, zero based
         */
        [External]
        public function addItem(itemConf:Object, adjustPosition:Boolean = true):int {
            var itemConfig:MenuItemConfig = _config.addItem(itemConf);
            log.debug("addItem(), color == " + itemConfig.color + ", overColor == " + itemConfig.overColor);
            createItem(itemConfig);
            updateModelHeight();
            if (_menuButtonContainer && model.visible && adjustPosition) {
                adjustDockPosition();
            }
            return _config.items.indexOf(itemConfig);
        }

        /**
         * Gets the current length of the menu, the number of items currently in the menu.
         */
        [External]
        public function get length():int {
            return _config.items.length;
        }

        /**
         * Removes the specified menu items.
         *
         * @param indexes the indexes of the menu items to be removed. If null, all items are removed.
         * @param should the menu be moved if the menu's height changes as a result of removing items
         * @return the new menu length
         */
        [External]
        public function removeItems(indexes:Array = null, adjustPosition:Boolean = true):int {
            log.debug("removeItems()");
            iterateViews(function(item:MenuItem, index:int):void {
                _config.removeItem(item);
                _dock.removeIcon(item);
            }, indexes);

            updateModelHeight();
            if (adjustPosition) {
                moveDockToNewHeight();
            }
            return _config.items.length;
        }

        private function get model():DisplayPluginModel {
            return DisplayPluginModel(_player.pluginRegistry.getPlugin(_name));
        }

        /**
         * Enables/disabled menu items.
         * @param enabled
         * @param indexes an array of menu item indexes, first item's index is zero
         */
        [External]
        public function enableItems(enabled:Boolean,  indexes:Array = null):void {
            iterateViews(function(item:MenuItem, index:int):void {
                item.enabled = enabled;
            }, indexes);
        }
        /**
         * Loads items from the specified URL. Sends a GET request to the specified URL and expects a JSON array
         * with menu items to be returned back. The format of this file should be the same as how the menu items
         * are configured for this plugin.
         * @param fromUrl
         * @param callback a function to be called when items are loaded and added
         */
        [External]
        public function loadItems(fromUrl:String, callback:Function = null):void {
            var loader:ResourceLoader = _player.createLoader();
            loader.addTextResourceUrl(fromUrl);
            loader.load(null, function(loader:ResourceLoader):void {
                var newItems:Array = ConfigParser.parse(String(loader.getContent(fromUrl))) as Array;
                log.debug("loaded " + newItems.length + "  items:", newItems);
                addItems(newItems);
                if (callback != null) {
                    callback();
                }
            });
        }

        public function onConfig(model:PluginModel):void {
            _model = model;
            _name = model.name;
            _config = new PropertyBinder(new MenuConfig()).copyProperties(model.config) as MenuConfig;
            log.debug("config", _config.items);
        }

        public function onLoad(player:Flowplayer):void {
            _player = player;
            createDock();

            if (_config.itemsUrl) {
                loadItems(_config.itemsUrl, function():void { _model.dispatchOnLoad(); });
            } else if (_config.items && _config.items.length > 0) {
                createItems(_config.items);
                updateModelHeight();
                _model.dispatchOnLoad();
            }

            createMenuButton(player);
        }

        override protected function onResize():void {
            _dock.setSize(width, height);
            updateModelHeight();
        }

        private function updateModelHeight():void {
            // in scrollable mode the height is set by the plugin configuration
            if (_config.scrollable) return;

            // the dock's height is actually determined on the heights of the menu items, update our model to reflect the real values
            updateModelProp("height", _dock.height);
        }

        internal function updateModelProp(prop:String, value:Object):void {
            var myModel:DisplayPluginModel = model;
            myModel[prop] = value;
            _player.pluginRegistry.updateDisplayProperties(myModel);
        }

        private function get horizontalPosConfigured():Boolean {
            var confObj:Object = _player.config.getObject("plugins")[_name];
            return confObj && (confObj.hasOwnProperty("left") || confObj.hasOwnProperty("right"));
        }

        private function get verticalPosConfigured():Boolean {
            var confObj:Object = _player.config.getObject("plugins")[_name];
            return confObj && (confObj.hasOwnProperty("top") || confObj.hasOwnProperty("bottom"));
        }

        public function getDefaultConfig():Object {
            return { width: 150, height: 100 };
        }

        private function createMenuButton(player:Flowplayer):void {
            if (! _config.button.dockedOrControls) return;

            if (_config.button.controls) {
                log.debug("onLoad() adding menu button to controls");
                var controlbar:* = player.pluginRegistry.plugins['controls'];

                // TODO: Container events should follow the same pattern as player, clip and plugin events
                controlbar.pluginObject.addEventListener(WidgetContainerEvent.CONTAINER_READY, addControlsMenuButton);
            }
        }

        private function addControlsMenuButton(event:WidgetContainerEvent):void {
            log.debug("addControlsMenuButton()");
            _menuButtonContainer = event.container;
            _menuButtonController = new MenuButtonController(_player,  model);
            _menuButtonContainer.addWidget(_menuButtonController, "time", false);

            if (this.stage) {
                adjustDockPosition();
            } else {
                // the position will be adjuster every time the menu becomes visible
                this.addEventListener(Event.ADDED_TO_STAGE, function(event:Event):void {
                    adjustDockPosition();
                });
            }
        }

        private function adjustDockPosition():void {
            if (horizontalPosConfigured && verticalPosConfigured) return;
            var myModel:DisplayPluginModel = model;

            if (! horizontalPosConfigured) {
                myModel.left = _menuButtonController.view.x;
                log.debug("adjustDockPosition(), menuButton.x = " + _menuButtonController.view.x);
                log.debug("adjustDockPosition(), horizontal menu position adjusted to " + myModel.position);
            }
            if (! verticalPosConfigured) {
                log.debug("stage == " + stage);
                myModel.bottom = stage.stageHeight - DisplayObject(_menuButtonContainer).y;
                log.debug("adjustDockPosition(), menuButtonContainer.y = " + _menuButtonContainer["y"]);
                log.debug("adjustDockPosition(), vertical menu position adjusted to " + myModel.position);
            }
            _player.animationEngine.animate(this, myModel, 0);
        }

        private function createDock():void {
            log.debug("createDock()");
            var dockConfig:DockConfig = new DockConfig();
            dockConfig.model = DisplayPluginModel(model.clone());
            dockConfig.model.display = "block";
            dockConfig.gap = 0;
            dockConfig.setButtons(_config.buttons);

            if (_config.button.dockedOrControls) {
                updateModelProp("display", "none");
            }
            dockConfig.scrollable = _config.scrollable;

            _dock = new Dock(_player, dockConfig);
            addChild(_dock);

            // distance, angle, color, alpha, blurX, blurY, strength,quality,inner,knockout ) all as type Number accept 'inner','knockout' and 'hideObject' (as Boolean).
            this.filters = [new DropShadowFilter(3, 270, 0x777777, 0.8, 15, 15, 2, 3)];

        }

        private function createItems(items:Array):void {
            log.debug("createItems(), creating " + items.length + " menu items");
            for (var i:uint = 0; i < items.length; i++) {
                createItem(items[i] as MenuItemConfig, i);
            }
        }

        private function createItem(itemConfig:MenuItemConfig, tabIndex:uint = 0):void {
            log.debug("createItem(), label == " + itemConfig.label);

            itemConfig.width = model.widthPx;
            var item:MenuItem = new MenuItem(_player, itemConfig, _player.animationEngine);
            itemConfig.view = item;
            item.tabEnabled = true;
            item.tabIndex = tabIndex;

            var menu:Menu = this;
            item.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
                if (! item.enabled) return;
                _player.animationEngine.fadeOut(menu);
                itemConfig.fireCallback(model);
                deselectOtherItemsInGroup(itemConfig);
            });
            item.height = itemConfig.height;

            _dock.addIcon(item);
        }

        private function deselectOtherItemsInGroup(itemConfig:MenuItemConfig):void {
            var itemsInGroup:Array = _config.itemsIn(itemConfig.group);
            for (var i:int; i < itemsInGroup.length; i++) {
                var relatedItem:MenuItemConfig = itemsInGroup[i] as MenuItemConfig;
                if (relatedItem != itemConfig) {
                    relatedItem.view.selected = false;
                }
            }
        }

        private function iterateViews(func:Function,  indexes:Array = null):void {
            var itemViews:Array = _dock.icons.concat();
            for (var i:int; i < itemViews.length; i++) {
                var view:MenuItem = itemViews[i];
                if (! indexes || (indexes && indexes.indexOf(i) >= 0)) {
                    func(view, i);
                }
            }
        }

        private function moveDockToNewHeight():void {
            var model:DisplayPluginModel = model;
            log.debug("moveDockToNewHeight(), plugin visible? " + model.visible);
            if (model.visible) {
                _player.animationEngine.animate(this, model);
            }
        }

        public function onBeforeCss(styleProps:Object = null):void {
        }

        public function css(styleProps:Object = null):Object {
            return null;
        }

        public function onBeforeAnimate(styleProps:Object):void {
        }

        public function animate(styleProps:Object):Object {
            return null;
        }
    }
}
