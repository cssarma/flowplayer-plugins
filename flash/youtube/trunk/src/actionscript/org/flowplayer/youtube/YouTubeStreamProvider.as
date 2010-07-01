/* * This file is part of Flowplayer, http://flowplayer.org * * By: Daniel Rossi, <electroteque@gmail.com>, Anssi Piirainen Flowplayer Oy * Copyright (c) 2009 Electroteque Multimedia, Flowplayer Oy * * Released under the MIT License: * http://www.opensource.org/licenses/mit-license.php */package org.flowplayer.youtube {import org.flowplayer.controller.StreamProvider;import flash.net.URLLoader;import flash.net.URLRequest;import flash.net.URLVariables;import flash.net.NetStream;import flash.net.NetConnection;import flash.display.Loader;import flash.display.DisplayObject;import flash.events.Event;import flash.events.IOErrorEvent;import flash.events.NetStatusEvent;import flash.events.TimerEvent;import flash.utils.Timer;import org.flowplayer.view.Flowplayer;import org.flowplayer.util.PropertyBinder;import org.flowplayer.util.Log;import org.flowplayer.util.Arrange;import org.flowplayer.model.Clip;import org.flowplayer.model.ClipError;import org.flowplayer.model.Playlist;import org.flowplayer.model.PluginEventType;import org.flowplayer.model.ClipEventType;import org.flowplayer.model.Plugin;import org.flowplayer.model.PluginModel;import org.flowplayer.model.ProviderModel;import org.flowplayer.model.DisplayProperties;import org.flowplayer.model.ClipEvent;import org.flowplayer.model.PlayerEvent;import org.flowplayer.controller.TimeProvider;import org.flowplayer.controller.VolumeController;import org.flowplayer.controller.ClipURLResolver;import org.flowplayer.controller.CompositeClipUrlResolver;import org.flowplayer.controller.DefaultClipURLResolver;import org.flowplayer.youtube.model.Gdata;import org.flowplayer.youtube.events.YouTubeEvent;import org.flowplayer.youtube.events.YouTubeDataEventimport org.flowplayer.youtube.events.YouTubePlayerError;import org.flowplayer.youtube.events.YouTubePlayerState;	/**	 * @author danielr     */public class YouTubeStreamProvider implements Plugin,ClipURLResolver,StreamProvider {	    private var _config:Config;	protected var log:Log = new Log(this);	private var _startedClip:Clip;	private var _playlist:Playlist;	private var _pauseAfterStart:Boolean;	private var _volumeController:VolumeController;	private var _seekTargetWaitTimer:Timer;	private var _seekTarget:Number;	private var _model:PluginModel;	private var _player:Flowplayer;    private var _bufferStart:Number;        private var _youTubePlayer:YouTubePlayer;    private var _youTubeBitratePlayer:YouTubePlayer;    private var _youTubeData:YouTubeData;        //private var _isWidescreen:Boolean = false;	private var _defaultClipUrlResolver:ClipURLResolver;   	private var _clipUrlResolver:ClipURLResolver;   	private var _failureListener:Function;        // state variables	private var _silentSeek:Boolean;	private var _paused:Boolean;	private var _stopping:Boolean;	private var _started:Boolean;    private var _timeProvider:TimeProvider;    private var _seeking:Boolean;        private var _screen:DisplayProperties;    private var _oldscreen:DisplayProperties;            private var _successListener:Function;    private var _resolved:Boolean = false;    //private var _gData:Gdata;    private var _qualityLevelsMapping:Array;    /**     * Called by the player to set my config.     */    public function onConfig(model:PluginModel):void {        _model = model;        _config = new PropertyBinder(new Config(), null).copyProperties(model.config) as Config;    }        public function set model(model:ProviderModel):void {		_model = model;		onConfig(model);	}		public function set player(player:Flowplayer):void {		_player = player;		onLoad(player);	}		protected function get youTubePlayer():YouTubePlayer {		return _youTubePlayer;	}		public function onLoad(player:Flowplayer):void { 				_player = player;				_screen = _player.pluginRegistry.getPlugin("screen") as DisplayProperties;  	  	_screen.getDisplayObject().addEventListener(Event.RESIZE, onScreenResize);			player.onVolume(function(event:PlayerEvent):void {			if (!youTubePlayer) return;			youTubePlayer.volume = Number(event.info);		});				_player.onFullscreen(function(event:PlayerEvent):void {			if (!youTubePlayer) return;			youTubePlayer.setSize(Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));		});			    _player.onFullscreenExit(function(event:PlayerEvent):void {			if (!youTubePlayer) return;			youTubePlayer.setSize(Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));		});				player.onMute(function(event:PlayerEvent):void {			if (!youTubePlayer) return;			youTubePlayer.mute();		});				player.onUnmute(function(event:PlayerEvent):void {			if (!youTubePlayer) return;			youTubePlayer.unMute();		});				/*		player.playlist.onStart(function(event:ClipEvent):void {			_player.screen.getDisplayObject().alpha = 1;			_player.screen.getDisplayObject().visible = true;		});*/				createClipUrlResolver();		initPlayer();	}        public function load(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = false):void {        log.info("doLoad");        _stopping = false;				if (_startedClip && _startedClip == clip && youTubePlayer) {			log.info("playing previous clip again, reusing existing connection and resuming");            _started = false;			clip.startDispatched = false;			doLoad();		} else {	        clip.onMetaData(onMetaData);	        clip.startDispatched = false;	        _startedClip = (_player.playlist.length > 0  ? null : clip);	        _pauseAfterStart = pauseAfterStart;	      	resolveClipUrl(clip, onClipUrlResolved);	    }    }        private function doLoad():void    {    	_bufferStart = 0;    	    	var level:String = clip.getCustomProperty("mappedBitrate") && _qualityLevelsMapping ? _qualityLevelsMapping[clip.getCustomProperty("mappedBitrate").bitrate] : _config.defaultQuality;    	    	log.debug("Quality Level: " + level);    	youTubePlayer.setSize(Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));    	youTubePlayer.loadVideoById(clip.url, clip.start, level);    	    	if (! _paused && canDispatchBegin()) {        	log.debug("dispatching onBegin");            clip.dispatchEvent(new ClipEvent(ClipEventType.BEGIN, _pauseAfterStart));      	}    }       /**     * Gdata      */        private function initYouTubeData():void {      	_youTubeData = new YouTubeData(_config.gdataApiURL + clip.url, _config.gdataApiVersion, _config.gdataApiFormat);      	_youTubeData.addEventListener(YouTubeDataEvent.ON_DATA, onData, false, 0, true);    	_youTubeData.addEventListener(YouTubeDataEvent.IOERROR, onDataError, false, 0, true);    	_youTubeData.load();    }        private function onData(event:YouTubeDataEvent):void {    	    	if (!clip.getCustomProperty("related")) {			clip.setCustomProperty("related", []);    		clip.customProperties["related"] = Gdata(event.data).relatedVideos;    	}    	    	if (!clip.getCustomProperty("gdata")) {			clip.setCustomProperty("gdata", {});    		clip.customProperties["gdata"] = Gdata(event.data);    	}    	    	_model.dispatch(PluginEventType.PLUGIN_EVENT, "onApiData", Gdata(event.data));		doLoad();		//initPlayer();    }        private function onDataError(event:YouTubeDataEvent):void {    	_youTubeData.removeEventListener(YouTubeDataEvent.ON_DATA, onData);    	_youTubeData.removeEventListener(YouTubeDataEvent.IOERROR, onDataError);    	_youTubeData = null;    	dispatchError(ClipError.STREAM_LOAD_FAILED, event.data);	    }        /**     * Youtube Bitrates Events     */        private function initPlayerForBitrates():void {    	if (_youTubeBitratePlayer) _youTubeBitratePlayer = null;    	    	_youTubeBitratePlayer = new YouTubePlayer(_config.apiPlayerURL);    	_youTubeBitratePlayer.addEventListener(YouTubeEvent.READY, onPlayerBitrateReady, false, 0, true);    	_youTubeBitratePlayer.addEventListener(YouTubeEvent.ERROR, onPlayerError, false, 0, true);    	_youTubeBitratePlayer.addEventListener(YouTubeEvent.STATE_CHANGE, onPlayerBitrateStateChange, false, 0, true);      	_youTubeBitratePlayer.load();    }        private function onPlayerBitrateReady(event:Event):void {      	_youTubeBitratePlayer.removeEventListener(YouTubeEvent.READY, onPlayerBitrateReady);      	_youTubeBitratePlayer.volume = 0;      	      	_youTubeBitratePlayer.loadVideoById(clip.url);    }        private function onPlayerBitrateStateChange(event:Event):void {		switch (Object(event).data) {			case YouTubePlayerState.PLAYING:			        	 	//capture quality levels into a bitrates list, stop the video and trigger clip resolving success.        	 	buildBitrateList();        	 	_youTubeBitratePlayer.stopVideo();        	 	_youTubeBitratePlayer.destroy();        	 	_youTubeBitratePlayer.removeEventListener(YouTubeEvent.ERROR, onPlayerError);        	 	_youTubeBitratePlayer.removeEventListener(YouTubeEvent.STATE_CHANGE, onPlayerBitrateStateChange);     			        	 	_youTubeBitratePlayer = null;        	 	if (_successListener != null) {					_successListener(clip);				}        	break;		}	}		/**     * Youtube Player Events     */		private function initPlayer():void {      	_youTubePlayer = new YouTubePlayer(_config.apiPlayerURL);      	_youTubePlayer.addEventListener(YouTubeEvent.READY, onPlayerReady, false, 0, true);    	_youTubePlayer.addEventListener(YouTubeEvent.ERROR, onPlayerError, false, 0, true);    	_youTubePlayer.addEventListener(YouTubeEvent.STATE_CHANGE, onPlayerStateChange, false, 0, true);      	_youTubePlayer.load();    }    private function onPlayerReady(event:Event):void {      	youTubePlayer.volume = _volumeController.volume;		youTubePlayer.setSize(Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));		_model.dispatchOnLoad();		//doLoad();    }        private function onPlayerError(event:Event):void {    	log.error("Error is", Object(event).data);    	switch (Object(event).data) {    		case YouTubePlayerError.STREAM_NOT_FOUND:    			if (canDispatchStreamNotFound()) {                    dispatchError(ClipError.STREAM_NOT_FOUND, "Requested video cannot be found or has been deleted");                }    		break;    		case YouTubePlayerError.EMBED_NOT_ALLOWED:			case YouTubePlayerError.EMBED_NOT_ALLOWED2:    			dispatchError(ClipError.STREAM_LOAD_FAILED, "Video failed to load due to embedding disabled");	    		break;    	}    }    private function onPlayerStateChange(event:Event):void {   		log.debug("State is", Object(event).data);      	switch (Object(event).data) {        	case YouTubePlayerState.ENDED:        		if (clip.duration - _player.status.time < 1)                {					                		//youTubePlayer.stopVideo();        	 			//youTubePlayer.destroy();                    	// we need to send buffer full at end of the video                        clip.dispatchEvent(new ClipEvent(ClipEventType.BUFFER_FULL)); // Bug #39                	                                 }                                //clip.dispatchEvent(new ClipEvent(ClipEventType.BUFFER_FULL));                //log.error(_player.status.time.toString());    				//dispatchEvent(new ClipEvent(ClipEventType.STOP));        	break;        	case YouTubePlayerState.PLAYING:        	 	dispatchEvent(new ClipEvent(ClipEventType.BUFFER_FULL));        	 	        	 	if (!clip.startDispatched) {         	 		sendMetaData();        	 	}        	break;        	case YouTubePlayerState.PAUSED:                  		if (!_player.status.ended) dispatchEvent(new ClipEvent(ClipEventType.PAUSE));			break;				case YouTubePlayerState.BUFFERING:				dispatchEvent(new ClipEvent(ClipEventType.BUFFER_EMPTY));			break;        	case YouTubePlayerState.CUED:        		        	break;      	}    }    private function onVideoPlaybackQualityChange(event:Event):void {        }        private function onScreenResize(event:Event):void {    	    }        private function resizePlayer(qualityLevel:String):void {    	var width:Number = Number(_config.videoFormats[qualityLevel].width);       	var height:Number = Number(_config.videoFormats[qualityLevel].height);		      	/*if (_isWidescreen) {        	// Widescreen videos (usually) fit into a 16:9 player.       	 	height = width * 9 / 16;     	} else {        	// Non-widescreen videos fit into a 4:3 player.        	height = width * 3 / 4;      	}*/            	//_youTubePlayerLoader.x = 0;      	//_youTubePlayerLoader.y = 0;    	//youTubePlayer.setSize(Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));    	//youTubePlayer.setSize(width,height);      	//Arrange.center(_youTubePlayerLoader, Number(_screen.getDisplayObject().width),Number(_screen.getDisplayObject().height));  	    }            private function buildBitrateList():void {    	var qualityLevels:Array = _youTubeBitratePlayer.availableQualityLevels;    	_qualityLevelsMapping = [];    	    	for (var key:String in qualityLevels) {            var level:String = qualityLevels[key];                        							if (!clip.getCustomProperty("bitrates")) clip.setCustomProperty("bitrates", []);							if (_config.videoFormats[level]) {				log.debug("Setting bitrate for clip with level " + level);				clip.customProperties["bitrates"].push(					{						"url": clip.url, 						"bitrate": Number(_config.videoFormats[level].bitrate),						"width": Number(_config.videoFormats[level].width), 						"height": Number(_config.videoFormats[level].height),						"format": level,						"type": _config.videoFormats[level].type,						"label": _config.videoFormats[level].label					}					);									 _qualityLevelsMapping[_config.videoFormats[level].bitrate] = level;				}            }    }        /**     * Metadata Events     */         private function sendMetaData():void {		log.info("sendMetaData, current clip " + clip);                var playbackQualityLevel:String = youTubePlayer.playbackQuality;        var width:Number = Number(_config.videoFormats[playbackQualityLevel].width);        var height:Number = Number(_config.videoFormats[playbackQualityLevel].height);        var metaData:Object = {width: width, height: height, duration: Math.ceil(youTubePlayer.duration), bytesTotal: youTubePlayer.videoBytesTotal};                clip.metaData = metaData;                //hack to force clip resizer to start at the correct size        clip.originalHeight = height;        clip.originalWidth = width;		//resizePlayer(playbackQualityLevel);        dispatchEvent(new ClipEvent(ClipEventType.METADATA));    	}			private function onMetaData(event:ClipEvent):void {		log.info("in YouTubeStremProvider.onMetaData: " + event.target);		if (! clip.startDispatched && !_pauseAfterStart) {        	clip.dispatch(ClipEventType.START, _pauseAfterStart);            clip.startDispatched = true;        } else {			log.info("seeking to frame zero");			seek(null, 0);			pause(null);			_pauseAfterStart = false;		}	}		/**	 * Clip Resolvers	 */        protected function getDefaultClipURLResolver():ClipURLResolver {    	return new DefaultClipURLResolver();    }            private function createClipUrlResolver():void {        _defaultClipUrlResolver = getDefaultClipURLResolver();    }        protected final function resolveClipUrl(clip:Clip, successListener:Function):void {			clipURLResolver.resolve(this, clip, successListener);	}		protected function onClipUrlResolved(clip:Clip):void {      	//obtain video information from the gdata xml feed for the video and then play the video.       	if (_config.enableGdata && !clip.getCustomProperty("gdata")) {       		initYouTubeData();    	      	} else {      		      		//initPlayer();      		doLoad();      	}    }        private function get clipURLResolver():ClipURLResolver {                    log.debug("get clipURLResolver,  clip.urlResolver = " + clip.urlResolvers + ", _clipUrlResolver = " + _defaultClipUrlResolver);        if (! clip || (clip.urlResolvers && clip.urlResolvers[0] == null)) {            clip.urlResolverObjects = [_defaultClipUrlResolver];            return _defaultClipUrlResolver;        }        // defined in clip?        if (clip.urlResolvers) {            _clipUrlResolver = CompositeClipUrlResolver.createResolver(clip.urlResolvers, _player.pluginRegistry);        } else {            // get all resolvers from repository            var configured:Array = _player.pluginRegistry.getUrlResolvers();            if (configured && configured.length > 0) {                log.debug("using configured URL resolvers", configured);                _clipUrlResolver = CompositeClipUrlResolver.createResolver(configured, _player.pluginRegistry);            }        }        if (! _clipUrlResolver) {            _clipUrlResolver = _defaultClipUrlResolver;        }        _clipUrlResolver.onFailure = function(message:String = null):void {            log.error("clip URL resolving failed: " + message);            clip.dispatchError(ClipError.STREAM_LOAD_FAILED, "failed to resolve clip url" + (message ? ": " + message : ""));        };        clip.urlResolverObjects = _clipUrlResolver is CompositeClipUrlResolver ? CompositeClipUrlResolver(_clipUrlResolver).resolvers : [_clipUrlResolver];        return _clipUrlResolver;    }        public function formatClipUrl(clip:Clip):void {    	var url:String = clip.url.split(":")[1];		clip.setResolvedUrl(this, url);    }            public function resolve(provider:StreamProvider, clip:Clip, successListener:Function):void {				//strip api: from the clip url to obtain the id		formatClipUrl(clip);		_successListener = successListener;					//setup the player to initially obtain the quality levels before resolving the clip and playing the video.			if (_config.bitratesOnStart && !clip.getCustomProperty("bitrates")) {				initPlayerForBitrates();			} else {				if (_successListener != null) {					_successListener(clip);				} 			}			}            /**     * Interface Methods     */                protected final function get pauseAfterStart():Boolean {		return _pauseAfterStart;	}			protected final function set pauseAfterStart(value:Boolean):void {		_pauseAfterStart = value;	}   	public function stop(event:ClipEvent, closeStreamAndConnection:Boolean = false):void {		_stopping = true;		if (closeStreamAndConnection) {                           log.debug("doStop(), closing netStream and connection");            youTubePlayer.stopVideo();            clip.setContent(null);        } else {            silentSeek = true;			youTubePlayer.pauseVideo();			youTubePlayer.seekTo(0, true);        }            			}	    public function seek(event:ClipEvent, seconds:Number):void {    	silentSeek = event == null;		log.debug("seekTo " + seconds);		_seekTarget = seconds;		doSeek(event, seconds);	          }        protected function doSeek(event:ClipEvent, seconds:Number):void {    	var target:Number = clip.start + seconds;    	//youTubePlayer.seekTo(Math.ceil(target), true);    	youTubePlayer.seekTo(target, isInBuffer(target) ? false : true);    	_seeking = true;    	_bufferStart = seconds;    	    	if (! silentSeek) {            startSeekTargetWait();        } else {            _seeking = false;        }        silentSeek = false;    	//dispatchEvent(event);    }        private function isInBuffer(seconds:Number):Boolean {        return bufferStart <= seconds - clip.start && seconds - clip.start <= bufferEnd;    }        private function startSeekTargetWait():void {        if (_seekTarget < 0) return;        if (_seekTargetWaitTimer && _seekTargetWaitTimer.running) return;        log.debug("starting seek target wait timer");        _seekTargetWaitTimer = new Timer(200);        _seekTargetWaitTimer.addEventListener(TimerEvent.TIMER, onSeekTargetWait);        _seekTargetWaitTimer.start();    }    private function onSeekTargetWait(event:TimerEvent):void {        if (time >= _seekTarget) {            _seekTargetWaitTimer.stop();            log.debug("dispatching onSeek");            dispatchEvent(new ClipEvent(ClipEventType.SEEK, _seekTarget));            _seekTarget = -1;            _seeking = false;        }    }        public function pause(event:ClipEvent):void {    	_stopping = false;    	youTubePlayer.pauseVideo();      }        public function resume(event:ClipEvent):void {    	_stopping = false;    	youTubePlayer.playVideo();    	dispatchEvent(event);    }            public function switchStream(event:ClipEvent, clip:Clip, netStreamPlayOptions:Object = null):void {    	    	var currentTime:Number = youTubePlayer.currentTime;	    youTubePlayer.loadVideoById(clip.url,currentTime);	    dispatchEvent(event);    }        protected final function dispatchEvent(event:ClipEvent):void {		if (! event) return;		log.debug("dispatching " + event + " on clip " + clip);		clip.dispatchEvent(event);	}		private function dispatchError(error:ClipError, info:String):void {		clip.dispatchError(error, info);	}		public function getVideo(clip:Clip):DisplayObject {		//return youTubePlayer as DisplayObject;		return youTubePlayer.content as DisplayObject;		//return _youTubePlayerLoader as DisplayObject;	}		public function attachStream(video:DisplayObject):void {			}		public function get fileSize():Number {		if (_player.state.code == 1) return 0;		return youTubePlayer.videoBytesTotal;	}		public function get time():Number {		if (_player.state.code ==1) return 0;		return getCurrentPlayheadTime();	}		protected function getCurrentPlayheadTime():Number {        return Math.ceil(Number(youTubePlayer.currentTime));        //return Number(Math.ceil(youTubePlayer.getCurrentTime()));	}		protected final function get clip():Clip {		return _playlist.current;	}		public function get bufferStart():Number {        if (! clip) return 0;        return _bufferStart - clip.start;    }    public function get bufferEnd():Number {        if (! clip) return 0;        if (_player.state.code ==1) return 0;        //log.error("Buffer Start: " + bufferStart + " Bytes: " +  youTubePlayer.getVideoBytesLoaded() + " Total: " + youTubePlayer.getVideoBytesTotal() + " Duration: " + clip.duration + " ");        return bufferStart + youTubePlayer.videoBytesLoaded / youTubePlayer.videoBytesTotal * (clip.duration - bufferStart);    }        public function set volumeController(controller:VolumeController):void {    	_volumeController = controller;    }        public function stopBuffering():void {    	    }        public function get stopping():Boolean {    	return _stopping;    }        public function set playlist(playlist:Playlist):void {    	_playlist = playlist;    }		public function get playlist():Playlist {		return _playlist;	}		public function addConnectionCallback(name:String, listener:Function):void {			}		public function addStreamCallback(name:String, listener:Function):void {			}		public function get netStream():NetStream {		return null;	}		public function get netConnection():NetConnection {		return null;	}		public function set timeProvider(timeProvider:TimeProvider):void {		_timeProvider = timeProvider;	}		protected final function get paused():Boolean {		return _paused;	}		protected final function get seeking():Boolean {    	return _seeking;    }        protected final function set silentSeek(value:Boolean):void {		_silentSeek = value;		log.info("silent mode was set to " + _silentSeek);	}			protected final function get silentSeek():Boolean {		return _silentSeek;	}    protected final function set seeking(value:Boolean):void {    	_seeking = value;    }    public function get allowRandomSeek():Boolean {       return true;    }        protected function canDispatchBegin():Boolean {		return true;	}   	   	protected function canDispatchStreamNotFound():Boolean {		return true;	}		    public function getDefaultConfig():Object {        return null;    }        public function get type():String {		return "youtube";		}		public function handeNetStatusEvent(event:NetStatusEvent):Boolean {    	return true;    }            public function set onFailure(listener:Function):void {		_failureListener = listener;    }		/**	 * Javascript API	 */		[External]	public function setPlaybackQuality(suggestedQuality:String):void {		if (!youTubePlayer) return;		youTubePlayer.playbackQuality = suggestedQuality;	}		[External]	public function getQualityLevels():Array {		if (!youTubePlayer) return undefined;		return youTubePlayer.availableQualityLevels;	}  }}