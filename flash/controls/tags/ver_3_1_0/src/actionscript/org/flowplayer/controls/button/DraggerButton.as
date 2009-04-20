 /* * This file is part of Flowplayer, http://flowplayer.org * *Copyright (c) 2008, 2009 Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.controls.button {    import flash.display.DisplayObject;import flash.display.DisplayObjectContainer;    import flash.display.Sprite;import org.flowplayer.controls.Config;	import org.flowplayer.controls.button.AbstractButton;    import org.flowplayer.view.AnimationEngine;		/**	 * @author api	 */	public class DraggerButton extends AbstractButton {		public function DraggerButton(config:Config, animationEngine:AnimationEngine) {			super(config, animationEngine);		}        protected function isToolTipEnabled():Boolean {            return false;        }        override public function get name():String {            return "dragger";        }        override protected function createFace():DisplayObjectContainer {            return SkinClasses.getDragger();        }        override protected function getButtonLeft():DisplayObject {            return new Sprite;        }        override protected function getButtonRight():DisplayObject {            return new Sprite();        }        override protected function getButtonTop():DisplayObject {            return new Sprite();        }        override protected function getButtonBottom():DisplayObject {            return new Sprite();        }	}}