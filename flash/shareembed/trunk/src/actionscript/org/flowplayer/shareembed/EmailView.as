/*
 * This file is part of Flowplayer, http://flowplayer.org
 *
 * By: Anssi Piirainen, <support@flowplayer.org>
 * Copyright (c) 2008, 2009 Flowplayer Oy
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 */
package org.flowplayer.shareembed {
    import flash.filters.GlowFilter;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.view.FlowStyleSheet;
	import org.flowplayer.view.Flowplayer;
	import org.flowplayer.view.StyleableSprite;
	
	import flash.display.BlendMode;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.AntiAliasType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;	
	import flash.text.TextFieldType;
	import flash.events.FocusEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.URLLoaderDataFormat;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.external.ExternalInterface;
	

	import org.flowplayer.shareembed.assets.SendBtn;

	/**
	 * @author api
	 */
	internal class EmailView extends StyleableSprite {

		private var _config:Config;
		private var _textMask:Sprite;
		private var _closeButton:CloseButton;
		private var _htmlText:String;
		private var _player:Flowplayer;
		private var _plugin:DisplayPluginModel;
		private var _originalAlpha:Number;
		
		private var _formContainer:Sprite;
		private var _titleLabel:TextField;
		private var _emailToLabel:TextField;
		private var _emailToInput:TextField;
		private var _messageLabel:TextField;
		private var _messageInput:TextField;
		private var _nameFromLabel:TextField;
		private var _nameFromInput:TextField;
		private var _emailFromLabel:TextField;
		private var _emailFromInput:TextField;
		
		private var _sendBtn:Sprite;
		
		private var _videoURL:String;
		
		private var _xPadding:int = 10;
		private var _yPadding:int = 5;
		
		public function EmailView(plugin:DisplayPluginModel, player:Flowplayer, config:Config) {
			super(null, player, player.createLoader());
			_plugin = plugin;
			_player = player;
			_config = config;
		

			createCloseButton();
		
		}

		override protected function onSetStyle(style:FlowStyleSheet):void {
			log.debug("onSetStyle");
			setupForm();
		}

		override protected function onSetStyleObject(styleName:String, style:Object):void {
			log.debug("onSetStyleObject");
			setupForm();
		}

		public function set html(htmlText:String):void {
			_htmlText = htmlText;
			if (! _htmlText) {
				_htmlText = "";
			}
			
		
		}
		
		public function get html():String {
			return _htmlText;
		}
		
		public function append(htmlText:String):String {
			html = _htmlText + htmlText;
			
			return _htmlText;
		}

		public function set closeImage(image:DisplayObject):void {
			if (_closeButton) {
				removeChild(_closeButton);
			}
			createCloseButton(image);
		}
		
		private function createLabelField():TextField
		{
			var field:TextField = _player.createTextField();
			field.selectable = false;
			field.autoSize = TextFieldAutoSize.LEFT;
			field.styleSheet = style.styleSheet;
			return field;
		}
		
		private function createInputField():TextField
		{
			var field:TextField = _player.createTextField();
			field.addEventListener(FocusEvent.FOCUS_IN, onTextInputFocusIn);
			field.addEventListener(FocusEvent.FOCUS_OUT, onTextInputFocusOut);
			field.type = TextFieldType.INPUT;
			field.alwaysShowSelection = true;
			field.tabEnabled = true;
            field.border = true;
			return field;
		}
		
		private function onTextInputFocusIn(event:FocusEvent):void
		{
			var field:TextField = event.target as TextField;
			field.borderColor = 0xCCCCCC;
		}
		
		private function onTextInputFocusOut(event:FocusEvent):void
		{
			var field:TextField = event.target as TextField;
			field.borderColor = 0x000000;
		}
		
		private function titleLabel():TextField
		{
			var field:TextField = createLabelField();
			field.width = 100;
            field.height = 20;            
            field.htmlText = "<span class=\"title\">Email this video</span>";
            return field;
		}
		
		private function emailToLabel():TextField
		{
			var field:TextField = createLabelField();            
			field.width = 150;
            field.height = 15;
            field.htmlText = "<span class=\"label\">Type in an email address <span id=" + 
            		"\"small\">(multiple addresses with commas)</span></span>";
            return field;
		}
		
		private function emailToInput():TextField
		{
			var field:TextField = createInputField();  
			field.mouseWheelEnabled	= true;
			field.width = 0.9 * width;
            field.height = 20;          
            return field;
		}
		
		private function messageLabel():TextField
		{
			var field:TextField = createLabelField();        
			field.width = 150;
            field.height = 15;     
            field.htmlText = "<span class=\"label\">Personal message <span id=" + 
            		"\"small\">(optional)</span></span>";
            return field;
		}
		
		private function messageInput():TextField
		{
			var field:TextField = createInputField();    
			field.multiline = true;    
			field.wordWrap = true;    
			field.mouseWheelEnabled	= true;
            field.width = 0.9 * width;
            field.height = 100;
            return field;
		}
		
		private function nameFromLabel():TextField
		{
			var field:TextField = createLabelField();            
			field.width = 100;
            field.height = 15;
            field.htmlText = "<span class=\"label\">Your name <span id=" + 
            		"\"small\">(optional)</span></span>";
            return field;
		}
		
		private function nameFromInput():TextField
		{
			var field:TextField = createInputField();     
			field.width = 0.5 * (width - (3 * _xPadding));
           	field.height = 20;      
            return field;
		}
		
		private function emailFromLabel():TextField
		{
			var field:TextField = createLabelField();     
			field.width = 100;
            field.height = 15;       
            field.htmlText = "<span class=\"label\">Your email address <span id=" + 
            		"\"small\">(optional)</span></span>";
            return field;
		}
		
		private function emailFromInput():TextField
		{
			var field:TextField = createInputField();  
			field.width = 0.5 * (width - (3 * _xPadding));
            field.height = 20;    
            return field;
		}

		private function setupForm():void
		{
			_formContainer = new Sprite();
			
			addChild(_formContainer);
			
			_formContainer.x = 0;
			_formContainer.y = 0;
			
			_titleLabel = titleLabel();
			_formContainer.addChild(_titleLabel);
       
       		_emailToLabel = emailToLabel();
			_formContainer.addChild(_emailToLabel);
        
			_emailToInput = emailToInput();
            _formContainer.addChild(_emailToInput);
            
            _messageLabel = messageLabel();
            addChild(_messageLabel);
            	
            _messageInput = messageInput();
            _formContainer.addChild(_messageInput);

            
            _nameFromLabel = nameFromLabel();
            addChild(_nameFromLabel);
            
			
			_emailFromLabel = emailFromLabel();
            addChild(_emailFromLabel);
			
            _nameFromInput = nameFromInput();
            _formContainer.addChild(_nameFromInput);
            
            
            _emailFromInput = emailFromInput();
            _formContainer.addChild(_emailFromInput);
            
            _sendBtn = new SendBtn() as Sprite;
            _sendBtn.buttonMode = true;
            _sendBtn.addEventListener(MouseEvent.MOUSE_DOWN, onSubmit);
            
            _formContainer.addChild(_sendBtn);
            
            
            _videoURL = ExternalInterface.call('function () { return window.location.href; }');
            
            
            arrangeForm();

		}
		
		private function onSubmit(event:MouseEvent):void
		{
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(_config.emailScriptURL);
			request.method = URLRequestMethod.POST;	
			
	
			
			var param:URLVariables = new URLVariables();
			param.name = _nameFromInput.text;
			param.email = _emailFromInput.text;
			param.to = _emailToInput.text;
			param.message = _messageInput.text + "\n\n <a href=\""+_videoURL+"\>"+_videoURL+"</a>";
			param.subject = _config.emailSubject;
	;
			
			param.dataFormat = URLLoaderDataFormat.VARIABLES;
			request.data = param;
			
			loader.load(request);
			loader.addEventListener(Event.COMPLETE, onSendSuccess);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onSendError);
		}
		
		private function onSendError(event:IOErrorEvent):void
		{
			log.debug(event.text);
		}
		
		private function onSendSuccess(event:Event):void
		{
			var loader:URLLoader = event.target as URLLoader;
			
			log.debug(loader.data.toString());
			
		}
		
		private function arrangeForm():void {
			_titleLabel.x = _xPadding;
            _titleLabel.y = _xPadding;
            
            _emailToLabel.x = _xPadding;
            _emailToLabel.y = _titleLabel.y + _titleLabel.height + (_yPadding * 2);
            
            _emailToInput.x = _xPadding;
            _emailToInput.y = _emailToLabel.y + _emailToLabel.height + _yPadding;
            
            _messageLabel.x = _xPadding;
            _messageLabel.y = _emailToInput.y + _emailToInput.height + _yPadding;
            
            _messageInput.x = _xPadding;
            _messageInput.y = _messageLabel.y + _messageLabel.height + _yPadding;
            
            _nameFromLabel.x = _xPadding;
            _nameFromLabel.y = _messageInput.y + _messageInput.height + _yPadding;
            
             _emailFromLabel.x = _nameFromLabel.x + _nameFromLabel.width + _xPadding;
            _emailFromLabel.y = _messageInput.y + _messageInput.height + _yPadding;
            
            _nameFromInput.x = _xPadding;
            _nameFromInput.y = _nameFromLabel.y + _nameFromLabel.height + _yPadding;
            
             _emailFromInput.x = _nameFromInput.x + _nameFromInput.width + _xPadding;
            _emailFromInput.y = _emailFromLabel.y + _emailFromLabel.height + _yPadding;
            
            _sendBtn.x = _xPadding;
            _sendBtn.y = _nameFromInput.y + _nameFromInput.height + (_yPadding * 2);
		}

		override protected function onResize():void {
			arrangeCloseButton();
			
			//_formContainer.x = 0;
			//_formContainer.y = 0;
			
			
			
			this.x = 0;
			this.y = 0;
		}

		override protected function onRedraw():void {
			//arrangeForm();
			arrangeCloseButton();
		}
		
		private function arrangeCloseButton():void {
			if (_closeButton && style) {
				_closeButton.x = width - _closeButton.width - 1 - style.borderRadius/5;
				_closeButton.y = 1 + style.borderRadius/5;
				setChildIndex(_closeButton, numChildren-1);
			}
		}
		
		private function createCloseButton(icon:DisplayObject = null):void {
			_closeButton = new CloseButton(icon);
			addChild(_closeButton);
			_closeButton.addEventListener(MouseEvent.CLICK, onCloseClicked);
		}
		
		private function onCloseClicked(event:MouseEvent):void {
			//ShareEmbed(_plugin.getDisplayObject()).removeListeners();
			_originalAlpha = _plugin.getDisplayObject().alpha;
			_player.animationEngine.fadeOut(_plugin.getDisplayObject(), 500, onFadeOut);
		}
		
		private function onFadeOut():void {
			log.debug("faded out");
//
			// restore original alpha value
			_plugin.alpha = _originalAlpha;
			_plugin.getDisplayObject().alpha = _originalAlpha;
			// we need to update the properties to the registry, so that animations happen correctly after this
			_player.pluginRegistry.updateDisplayProperties(_plugin);
			
			//Content(_plugin.getDisplayObject()).addListeners();
		}

		override public function set alpha(value:Number):void {
			super.alpha = value;
			
		}
	}
}
