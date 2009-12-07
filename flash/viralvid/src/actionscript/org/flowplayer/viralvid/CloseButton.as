/* * This file is part of Flowplayer, http://flowplayer.org *  * By: Anssi Piirainen, <support@flowplayer.org> * Copyright (c) 2008, 2009 Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.viralvid {	import flash.display.DisplayObject;	
	import flash.display.Sprite;	import flash.events.MouseEvent;		/**	 * @author api	 */	internal class CloseButton extends Sprite {		private var _icon:DisplayObject;
		public function CloseButton(icon:DisplayObject = null)  {			_icon = icon || new CloseIcon();			_icon.width = 10;			_icon.height = 10;			addChild(_icon);			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);				addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);			onMouseOut();			buttonMode = true;		}				private function onMouseOut(event:MouseEvent = null):void {			_icon.alpha = 0.7;		}		private function onMouseOver(event:MouseEvent):void {			_icon.alpha = 1;		}	}}