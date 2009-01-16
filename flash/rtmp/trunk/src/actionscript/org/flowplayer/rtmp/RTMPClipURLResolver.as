/*     *    Copyright 2008 Anssi Piirainen * *    This file is part of FlowPlayer. * *    FlowPlayer is free software: you can redistribute it and/or modify *    it under the terms of the GNU General Public License as published by *    the Free Software Foundation, either version 3 of the License, or *    (at your option) any later version. * *    FlowPlayer is distributed in the hope that it will be useful, *    but WITHOUT ANY WARRANTY; without even the implied warranty of *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *    GNU General Public License for more details. * *    You should have received a copy of the GNU General Public License *    along with FlowPlayer.  If not, see <http://www.gnu.org/licenses/>. */package org.flowplayer.rtmp {	import org.flowplayer.controller.ClipURLResolver;	import org.flowplayer.model.Clip;		/**	 * @author api	 */	public class RTMPClipURLResolver implements ClipURLResolver {		public function resolve(clip:Clip, successListener:Function):void {			if (isRtmpUrl(clip.completeUrl)) {				var url:String = clip.completeUrl;				var lastSlashPos:Number = url.lastIndexOf("/");				successListener(url.substring(lastSlashPos));				return;			}			successListener(clip.baseUrl ? clip.completeUrl : clip.url);		}				public function set onFailure(listener:Function):void {		}				public static function isRtmpUrl(url:String):Boolean {			return url && url.toLowerCase().indexOf("rtmp") == 0;		}	}}