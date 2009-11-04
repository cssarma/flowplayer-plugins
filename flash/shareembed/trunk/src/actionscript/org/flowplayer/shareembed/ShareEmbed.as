/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com> * Copyright (c) 2009 Electroteque Multimedia * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.shareembed {    import com.adobe.serialization.json.JSON;	import flash.display.LoaderInfo;    import flash.display.BlendMode;    import flash.display.Sprite;    import flash.events.MouseEvent;    import flash.text.AntiAliasType;    import flash.text.TextField;    import org.flowplayer.controller.ResourceLoader;    import org.flowplayer.controller.ResourceLoaderImpl;    import org.flowplayer.model.Clip;    import org.flowplayer.model.ClipEvent;    import org.flowplayer.model.DisplayPluginModel;    import org.flowplayer.model.DisplayProperties;    import org.flowplayer.model.Plugin;    import org.flowplayer.model.PluginEventType;    import org.flowplayer.model.PluginModel;    import org.flowplayer.view.FlowStyleSheet;    import org.flowplayer.view.Styleable;        import org.flowplayer.util.PropertyBinder;    import org.flowplayer.view.AbstractSprite;    import org.flowplayer.view.Flowplayer;        import org.flowplayer.shareembed.assets.EmailBtn;    import org.flowplayer.shareembed.assets.EmbedBtn;    import org.flowplayer.shareembed.assets.ShareBtn;    /**	 * A Subtitling and Captioning Plugin. Supports the following:	 * <ul>	 * <li>Loading subtitles from the Timed Text or Subrip format files.</li>	 * <li>Styling text from styles set in the Time Text format files.</li>	 * <li>Loading subtitles or cuepoints from a JSON config.</li>	 * <li>Loading subtitles or cuepoints from embedded FLV cuepoints.</li>	 * <li>Controls an external content plugin.</li>	 * <li>Working with the Javascript captions plugin, it enables a scrolling cuepoint thumbnail menu.</li>	 * </ul>	 * <p>	 * To setup an external subtitle caption file the config would look like so:	 * 	 * captionType: 'external'	 * 	 * For Timed Text	 *	 * captionUrl: 'timedtext.xml'	 * 	 * For Subrip	 * 	 * captionUrl: 'subrip.srt'	 * 	 * <p>	 * To enable the captioning to work properly a caption target must link to a content plugin like so:	 * 	 * captionTarget: 'content'	 * 	 * Where content is the config for a loaded content plugin.	 *	 * <p>	 * 	 * To be able to customised the subtitle text a template string is able to tell the captioning plugin	 * which text property is to be used for the subtitle text which is important for embedded cuepoints. It also	 * enables to add extra properties to the text like so:	 * 	 * template: '{text} {time} {custom}' 	 * 	 * <p>	 * To enable simple formatting of text if Timed Text has style settings, 	 * only "fontStyle", "fontWeight" and "textAlign" properties are able to be set like so:	 * 	 * simpleFormatting: true	 * 	 * @author danielr	 */	public class ShareEmbed extends AbstractSprite implements Plugin, Styleable {				private var _player:Flowplayer;		private var _model:PluginModel;		private var _config:Config;		private var _loader:ResourceLoader;		private var _viewModel:DisplayPluginModel;		private var _text:TextField;		private var oldDisplayProperties:DisplayProperties;		private var screen:DisplayProperties;				private var embedBtn:Sprite;		private var emailBtn:Sprite;		private var shareBtn:Sprite;				private var _embedView:EmbedView;		/**		 * Sets the plugin model. This gets called before the plugin		 * has been added to the display list and before the player is set.		 * @param plugin		 */		public function onConfig(plugin:PluginModel):void {			_model = plugin;			_config = new PropertyBinder(new Config(), null).copyProperties(plugin.config) as Config;		}				override protected function onResize():void {            //_text.x = 10;            //_text.width = width - 20;                   //_text.y = height - 30;//            _text.y = coverFlow.y + height;        }		public function onLoad(player:Flowplayer):void {			_player = player;						_player.playlist.onLastSecond(onBeforeFinish);			_loader = _player.createLoader();			            emailBtn = new EmailBtn() as Sprite;            _player.addToPanel(emailBtn, {right:0, bottom:0, zIndex: 100});            emailBtn.visible = false;                        embedBtn = new EmbedBtn() as Sprite;            _player.addToPanel(embedBtn, {right:0, bottom:0, zIndex: 100});            embedBtn.visible = false;                        shareBtn = new ShareBtn() as Sprite;            _player.addToPanel(shareBtn, {right:0, bottom:0, zIndex: 100});            shareBtn.visible = false;           // createTextField();            _model.dispatchOnLoad();        }				public function getDefaultConfig():Object {			//return {width: "80%"};			return {top: 20, left: 0, width: "80%", height: "80%"};		}				[External]		public function email():void		{					}				[External]        public function embed():void        {            _embedView = new EmbedView(_model as DisplayPluginModel, _player);            _embedView.setSize(width, height);			_embedView.x = 0;			_embedView.y = 0;            _embedView.style = createStyleSheet(null);         	addChild(_embedView);         	_embedView.html = getEmbedCode();					            /*screen = _player.pluginRegistry.getPlugin("screen") as DisplayProperties;            oldDisplayProperties = screen;            _player.animationEngine.animate(coverFlow, {alpha:1}, 0.5);            _text.visible = true;            _player.animationEngine.animate(screen.getDisplayObject(), _config.screen, 400, showRelatedVideos);*/        }                [External]        public function share():void        {        	        }                private function getEmbedCode():String        {        	var code:String =         	'<object id="captions_api" width="' + stage.width + '" height="' + stage.height +'" type="application/x-shockwave-flash" data="../flowplayer.swf?0.8972209213014333"> ' +				'<param value="true" name="allowfullscreen"/>' +				'<param value="sameDomain" name="allowscriptaccess"/>' +				'<param value="high" name="quality"/>' + 				'<param value="true" name="cachebusting"/>' + 				'<param value="#000000" name="bgcolor"/>' +				'<param value="config=' + stage.loaderInfo.parameters["config"] + '" name="flashvars"/>' + 			'</object>';			code = code.replace(/\</g, "&lt;").replace(/\>/g, "&gt;"); 			return code;        }                private function createStyleSheet(cssText:String = null):FlowStyleSheet {						var styleSheet:FlowStyleSheet = new FlowStyleSheet("#content", cssText);			// all root style properties come in config root (backgroundImage, backgroundGradient, borderRadius etc)			addRules(styleSheet, _model.config);			// style rules for the textField come inside a style node			addRules(styleSheet, _model.config.style);			return styleSheet;		}				private function addRules(styleSheet:FlowStyleSheet, rules:Object):void {			var rootStyleProps:Object;			for (var styleName:String in rules) {				log.debug("adding additional style rule for " + styleName);				if (FlowStyleSheet.isRootStyleProperty(styleName)) {					if (! rootStyleProps) {						rootStyleProps = new Object();					}                    log.debug("setting root style property " + styleName + " to value " + rules[styleName]);					rootStyleProps[styleName] = rules[styleName];				} else {					styleSheet.setStyle(styleName, rules[styleName]);				}			}			styleSheet.addToRootStyle(rootStyleProps);		}				private function showButtons():void		{			//_model.dispatch(PluginEventType.PLUGIN_EVENT, "onShow");				emailBtn.visible = true;			embedBtn.visible = true;			shareBtn.visible = true;						emailBtn.x = screen.getDisplayObject().width + 5;			emailBtn.y = 0;						embedBtn.x = screen.getDisplayObject().width + 5;			embedBtn.y = emailBtn.height + 2;						shareBtn.x = screen.getDisplayObject().width + 5;			shareBtn.y = emailBtn.height + 2 + embedBtn.height + 2;						emailBtn.addEventListener(MouseEvent.CLICK, onShowEmailPanel);			embedBtn.addEventListener(MouseEvent.CLICK, onShowEmbedPanel);			shareBtn.addEventListener(MouseEvent.CLICK, onShowSharePanel);		}				private function onBeforeFinish(event:ClipEvent):void		{			show();		}				private function onShowEmailPanel():void		{			email();		}				private function onShowEmbedPanel(event:MouseEvent):void		{			embed();		}				private function onShowSharePanel():void		{			share();		}				[External]        public function show():void        {            screen = _player.pluginRegistry.getPlugin("screen") as DisplayProperties;            oldDisplayProperties = screen;            //_text.visible = true;            _player.animationEngine.animate(screen.getDisplayObject(), _config.screen, 400, showButtons);        }				public function css(styleProps:Object = null):Object {			return {};		}				public function animate(styleProps:Object):Object {			return {};		}					}}