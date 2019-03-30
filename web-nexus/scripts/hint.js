// create a new Hint instance
function Hint(containerElement, textElement){
	this.containerElement = $(containerElement);
	this.textElement = $(textElement);
	this.pointerOffset = {x:15,y:15};	// {x:15,y:15} to display hint 15 pixels away from the pointer
	this.hideTimeout = 0;	// timeout in millisecond before hiding the hint
	this.hoverElement = null;
	this.anchored = false;
	this.x = 0;
	this.y = 0;

	Element.setOpacity(this.containerElement, 0.85);

	// called when mouse leaves an element
	this._mouseout = function(event){
		this.hide();
		// stop observing mouseout event
		if(this.hoverElement){
			Event.stopObserving(this.hoverElement, 'mouseout', this._b_mouseout);
			this.hoverElement = null;
		}
	};

	// called when mouse move on the document
	this._mousemove = function(event){
		if(Event.pointerY){
			this.pointerX = Event.pointerX(event);
			this.pointerY = Event.pointerY(event);
			this.x = Event.pointerX(event) + this.pointerOffset.x;
			this.y = Event.pointerY(event) + this.pointerOffset.y;
		}

		this._updatePosition();
	};

	// called when user clicks on the document
	this._click = function(event){
		this.hide();
	};

	// create bound functions for mousemove(), mouseout() and click()
	this._b_mouseout = this._mouseout.bindAsEventListener(this);
	this._b_mousemove = this._mousemove.bindAsEventListener(this);
	this._b_click = this._click.bindAsEventListener(this);

	// update width/height of containerElement
	this._updateSize = function(){
		var dimensions = (this.autoSize?textElement:containerElement).getDimensions();
		this.width = dimensions.width;
		this.height = dimensions.height;
	}

	this._updatePosition = function(){
		if(typeof getWindowDimensions == "undefined") return;

//		if(!this.containerElement.visible()) return;

		// update hint size, height may have changed by the text
		//this._updateSize();

		// retrieve window dimensions
		var dimensions = getWindowDimensions();

		if(this.x + this.width > dimensions.width) this.x = dimensions.width - this.width;
		if(this.y + this.height > dimensions.height){
			this.y = this.pointerY - this.pointerOffset.y - this.height;
		}
		if(this.x < 0) this.x = 0;
		if(this.y < 0) this.y = 0;

		if(this.anchored){
			var position = Position.cumulativeOffset(this.anchored);
			this.x = position[0] + Element.getWidth(this.anchored);
			this.y = position[1];

			if(this.x + this.width > dimensions.width) this.x = position[0]-this.width;
		}

		if(Event.pointerY){
			this.containerElement.style.left = this.x + 'px';
			this.containerElement.style.top = this.y + 'px';
		}
	};

	this.show = function(text, element, anchored){
		if(anchored)
			this.anchored = $(element);
		else
			this.anchored = null;

		this.textElement.innerHTML = text;

		// if element is defined, hide hint when mouse leave the element
		if(element && !anchored){
			this.hoverElement = $(element);
			Event.observe(element, 'mouseout', this._b_mouseout);
		}

		this._updateSize();
		this._updatePosition();

		this.containerElement.style.display = 'block';

		if(this.hideTimeout > 0)
			new PeriodicalExecuter(function(pe) { this.hide(); pe.stop(); }.bind(this), this.hideTimeout/1000.0);
	};

	this.hide = function(){
		this.containerElement.style.display = 'none';
	};

	Event.observe(document, 'mousemove', this._b_mousemove);
	Event.observe(document, 'click', this._b_click);
	Event.observe(window, 'resize', this._b_mousemove);
}