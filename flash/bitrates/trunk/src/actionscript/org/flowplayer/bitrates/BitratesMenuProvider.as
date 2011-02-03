/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi <electroteque@gmail.com>, Anssi Piirainen <api@iki.fi> Flowplayer Oy * Copyright (c) 2009, 2010 Electroteque Multimedia, Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.bitrates {    import flash.display.DisplayObject;          import org.flowplayer.model.Clip;    import org.flowplayer.model.ClipEvent;    import org.flowplayer.model.PlayerEvent;    import org.flowplayer.model.Plugin;    import org.flowplayer.model.PluginModel;    import org.flowplayer.view.AbstractSprite;    import org.flowplayer.view.Flowplayer;    import org.flowplayer.view.Styleable;    import org.flowplayer.util.PropertyBinder;        import org.flowplayer.bitrates.ui.DropdownMenu;    import org.flowplayer.bitrates.ui.DropdownMenuEvent;        public class BitratesMenuProvider extends AbstractSprite  implements Plugin, Styleable {        private var _config:Config;        private var _player:Flowplayer;        private var _model:PluginModel;        private var _bitrateMenu:DropdownMenu;               public function onConfig(model:PluginModel):void {            log.debug("onConfig(_)");                        _config = new PropertyBinder(new Config()).copyProperties(model.config) as Config;            _model = model;                   }        public function onLoad(player:Flowplayer):void {            log.debug("onLoad()");            _player = player;                                    _bitrateMenu = new DropdownMenu(_player.animationEngine, "#000000", "#FFFFFF");            _bitrateMenu.addEventListener(DropdownMenuEvent.CHANGE, function(event:DropdownMenuEvent):void {                //_config.playerEmbed.buttonColor = event.value;                //changeCode();            });                        addChild(_bitrateMenu);            _player.playlist.onBeforeBegin(function(event:ClipEvent):void {            	                for each(var props:Object in _player.playlist.current.getCustomProperty("bitrates")) {                    _bitrateMenu.addItem(props["label"] ? props["label"] : props["bitrate"] + "k", props["bitrate"]);                }            });                                                            _model.dispatchOnLoad();        }               public function getDefaultConfig():Object {            return {                top: "45%",                left: "50%",                opacity: 1,                borderRadius: 15,                border: 'none',                width: "80%",                height: "80%"            };        }                public function css(styleProps:Object = null):Object {            return {};        }        public function animate(styleProps:Object):Object {            return {};        }        public function onBeforeCss(styleProps:Object = null):void {                   }        public function onBeforeAnimate(styleProps:Object):void {                    }    }}