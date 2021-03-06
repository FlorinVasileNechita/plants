package com.saybot.plants.view.entity
{
	import com.saybot.AssetsMgr;
	import com.saybot.GameConst;
	import com.saybot.plants.StarlingMain;
	import com.saybot.plants.interfaces.IActor;
	import com.saybot.plants.states.PlayfieldView;
	import com.saybot.plants.vo.Entity;
	import com.saybot.utils.CollisionUtil;
	import com.saybot.utils.GraphicsCanvas;
	import com.saybot.utils.ParticleBuilder;
	
	import flash.geom.Rectangle;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import dragonBones.Armature;
	
	import starling.animation.IAnimatable;
	import starling.animation.Juggler;
	import starling.core.Starling;
	import starling.display.DisplayObject;
	import starling.display.Sprite;
	import starling.events.Event;
	import starling.extensions.PDParticleSystem;

	public class EntityViewBase extends Sprite implements IAnimatable
	{
		public var speedX:Number;
		
		public var speedY:Number;
		
		public var accX:Number;
		
		public var accY:Number;
		
		public var vo:Entity;
		public var display:DisplayObject;
		
		protected var state:String;
		protected var stateLastTime:Number;
		
		protected var _debugInfo:GraphicsCanvas;
		protected var _colBox:Rectangle;
		protected var _keepColBox:Boolean = false;
		
		protected var _isPaused:Boolean;
		
		public function EntityViewBase(vo:Entity)
		{
			this.vo = vo;
			if(display)
				this.addChild(display);
			Starling.juggler.add(this);
			this.addEventListener(Event.ADDED_TO_STAGE, initializeViews);
		}
		
		private function initializeViews(evt:Event):void {
			updateCollisionBox();
		}
		
		protected function updateCollisionBox():void {
			if(!(_keepColBox && _colBox)) {
				_colBox = this.bounds;
			}
		}
		
		public function advanceTime(time:Number):void {
			if(_isPaused)
				return;
			updateCollisionBox();
		}
		
		public function switchState(st:String):void {
			state = st;
			stateLastTime = 0;
		}
		
		override public function dispose():void {
			Starling.juggler.remove(this);
			if(display) {
				this.removeChild(display);
				display.dispose();
				display = null;
			}
			if(_debugInfo) {
				this.removeChild(_debugInfo);
				_debugInfo.dispose();
				_debugInfo = null;
			}
			super.dispose();
		}
		
		public function get playfield():PlayfieldView {
			return StarlingMain.getInstance().crtStateView as PlayfieldView;
		}
		
		public function toggleDebugInfo(val:Boolean):void {
			if(_debugInfo == null && val) {
				_debugInfo = new GraphicsCanvas(_colBox.width+1, _colBox.height+1);
				_debugInfo.x = _colBox.left - _colBox.x;
				_debugInfo.y = _colBox.top - _colBox.y;
				this.addChild(_debugInfo);
				_debugInfo.drawRect(0, 0, _colBox.width, _colBox.height, 0x00ff00);
				_debugInfo.refreshCanvas();
			} else if(_debugInfo){
				_debugInfo.visible = val;
			}	
		}
		
		public function get colBox():Rectangle {
			return _colBox;
		}
		
		protected function getColEntity(originTargets:Array, sameLane:Boolean=true):EntityViewBase {
			var targets:Array = [];
			var entiView:EntityViewBase;
			if(sameLane) {
				for each(entiView in originTargets) {
					if(Object(entiView.vo).lane == Object(this.vo).lane)
						targets.push(entiView);
				}
			} else {
				targets = originTargets;
			}
			for each(entiView in targets) {
				if(CollisionUtil.checkCol(this.colBox, entiView.colBox)) {
					return entiView;
				}
			}
			return null;
		}
		
		public function playParticleEffect(name:String, ox:Number, oy:Number, duration:Number=Number.MAX_VALUE, finishCallback:Function=null):void {
			name = name.toUpperCase();
			var ptl:PDParticleSystem = ParticleBuilder.build(name+"_XML", name+"_PNG");
			this.addChild(ptl);
			ptl.x = ox;
			ptl.y = oy;
			ptl.emitterX = ptl.emitterY = 0;
			Starling.juggler.add(ptl);
			ptl.start(duration);
			if(duration != Number.MAX_VALUE) {
				var id:int = setTimeout(function():void {
					clearTimeout(id);
					ptl.removeFromParent(true);
					Starling.juggler.remove(ptl);
					ptl = null;
					if(finishCallback) 
						finishCallback.call();
				}, duration);
			}
		}
		
		public function dist2Entity(enti:EntityViewBase):Number {
			return Math.abs(this.x - enti.x)
		}
		
		public function set isPaused(val:Boolean):void { _isPaused = val; }
	}
}