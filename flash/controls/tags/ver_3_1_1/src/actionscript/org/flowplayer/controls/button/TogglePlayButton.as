/* * This file is part of Flowplayer, http://flowplayer.org * *Copyright (c) 2008, 2009 Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.controls.button {    import flash.display.DisplayObjectContainer;    import org.flowplayer.controls.Config;    import org.flowplayer.view.AnimationEngine;    /**	 * @author api	 */	public class TogglePlayButton extends AbstractToggleButton {		public function TogglePlayButton(config:Config, animationEngine:AnimationEngine) {			super(config, animationEngine);		}        override public function get name():String {            return "play";        }        override protected function createUpStateFace():DisplayObjectContainer {            return DisplayObjectContainer(SkinClasses.getPlayButton());        }        override protected function createDownStateFace():DisplayObjectContainer {            return DisplayObjectContainer(SkinClasses.getPauseButton());        }				override protected function get tooltipLabel():String {            log.debug("get tooltipLabel, isDown " + isDown);            return isDown ? config.tooltips.pause : config.tooltips.play;		}	}}