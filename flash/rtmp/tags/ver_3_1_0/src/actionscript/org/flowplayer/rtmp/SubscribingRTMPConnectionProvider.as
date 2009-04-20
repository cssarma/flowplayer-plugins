/*     *    Copyright 2008, 2009 Flowplayer Oy * *    This file is part of FlowPlayer. * *    FlowPlayer is free software: you can redistribute it and/or modify *    it under the terms of the GNU General Public License as published by *    the Free Software Foundation, either version 3 of the License, or *    (at your option) any later version. * *    FlowPlayer is distributed in the hope that it will be useful, *    but WITHOUT ANY WARRANTY; without even the implied warranty of *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *    GNU General Public License for more details. * *    You should have received a copy of the GNU General Public License *    along with FlowPlayer.  If not, see <http://www.gnu.org/licenses/>. */package org.flowplayer.rtmp {    import org.flowplayer.controller.StreamProvider;import org.flowplayer.model.ClipError;		import flash.events.TimerEvent;			import org.flowplayer.model.Clip;	import org.flowplayer.model.ClipEvent;	import org.flowplayer.rtmp.RTMPConnectionProvider;		import flash.net.NetConnection;	import flash.utils.Timer;		/**	 * @author api	 */	internal class SubscribingRTMPConnectionProvider extends RTMPConnectionProvider {		private var _onSuccess:Function;		private var _subscribeRepeatTimer:Timer;		private var _clip:Clip;		public function SubscribingRTMPConnectionProvider(config:Config) {			super(config);		}				override public function connect(provider:StreamProvider, clip:Clip, successListener:Function, objectEncoding:uint, ...rest):void {			clip.onConnectionEvent(onConnectionEvent);			_clip = clip;			_onSuccess = successListener;			super.connect(provider, clip, function(connection:NetConnection):void {				subscribe();			}, objectEncoding, rest);		}				private function onConnectionEvent(event:ClipEvent):void {            log.debug("received " + event.info);			if (! event.info == "onFCSubscribe") return;			if (! (event.info2 && event.info2.hasOwnProperty("code"))) return;						_subscribeRepeatTimer.stop();			if (event.info2.code == "NetStream.Play.Start") {				_onSuccess(connection);			} else if (event.info2.code == "NetStream.Play.StreamNotFound") {				_clip.dispatchError(ClipError.STREAM_NOT_FOUND);			}		}		private function subscribe():void {			onSubscribeRepeat();			_subscribeRepeatTimer = new Timer(2000);			_subscribeRepeatTimer.addEventListener(TimerEvent.TIMER, onSubscribeRepeat);			_subscribeRepeatTimer.start();		}		private function onSubscribeRepeat(event:TimerEvent = null):void {			log.debug("calling FCSubscribe for stream '" + _clip.url + "'");			connection.call("FCSubscribe", null, _clip.url);		}	}}