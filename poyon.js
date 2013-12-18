// Generated by CoffeeScript 1.6.3
(function() {
  var log,
    __slice = [].slice,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  log = function() {
    var args;
    args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return console.log.apply(console, args);
  };

  (function($) {
    var Circle, FlickCircle, Geometry, Point, Poyon, PreloadImage, Render, ScrollCircle, ScrollSensor, Singleton, Timer, VelocityPoint, WarpCircle, WarpPoint;
    Poyon = (function() {
      Poyon.prototype.defaults = {
        warp: true,
        scroll: true,
        flick: true,
        vertexNumber: 8,
        warpLevel: 0.5,
        warpAngularVelocity: 0.05,
        spring: 0.015,
        friction: 0.93
      };

      function Poyon($el, options) {
        this.$el = $el;
        this.update = __bind(this.update, this);
        this.options = _.extend({}, this.defaults, options);
        if (this.options.radius == null) {
          throw "no radius parameter";
        }
        this.circle = new Circle(this.options.vertexNumber, this.options.radius);
        if (this.options.warp) {
          this.circle = new WarpCircle(this.circle, this.options.warpLevel, this.options.warpAngularVelocity);
        }
        if (this.options.scroll) {
          this.circle = new ScrollCircle(this.circle, this.options.spring, this.options.friction);
        }
        if (this.options.flick) {
          this.circle = new FlickCircle(this.circle, this.$el, this.options.spring, this.options.friction);
        }
        this.render = new Render(this.$el, this.circle);
        this.img = new PreloadImage(this.$el.data("image"));
        this.img.promise().then(this.render.setImage);
        Timer.getInstance().add(this);
      }

      Poyon.prototype.update = function() {
        this.circle.update();
        return this.render.run();
      };

      return Poyon;

    })();
    Render = (function() {
      function Render($el, circle) {
        var _ref;
        this.$el = $el;
        this.circle = circle;
        this.mainRendering = __bind(this.mainRendering, this);
        this.run = __bind(this.run, this);
        this.setImage = __bind(this.setImage, this);
        _ref = [this.$el.width(), this.$el.height()], this.width = _ref[0], this.height = _ref[1];
        this.offset = {
          x: this.width * 0.5,
          y: this.height * 0.5
        };
        this.ctx = this.$el[0].getContext("2d");
        this.ctx.fillStyle = this.ctx.strokeStyle = "#e6e5e5";
      }

      Render.prototype.setImage = function(img) {
        return this.ctx.fillStyle = this.ctx.createPattern(img, "repeat");
      };

      Render.prototype.run = function() {
        this.ctx.clearRect(0, 0, this.width, this.height);
        this.ctx.beginPath();
        this.mainRendering();
        this.ctx.closePath();
        return this.ctx.fill();
      };

      Render.prototype.mainRendering = function() {
        var start,
          _this = this;
        start = this.circle.at(-1).getCenter(this.circle.at(0));
        start = Geometry.add(start, this.offset);
        this.ctx.moveTo(start.x, start.y);
        this.circle.curvePointEach(function(sub, pos) {
          sub = Geometry.add(sub, _this.offset);
          pos = Geometry.add(pos, _this.offset);
          return _this.ctx.quadraticCurveTo(sub.x, sub.y, pos.x, pos.y);
        });
        return this.ctx.stroke();
      };

      return Render;

    })();
    Circle = (function() {
      var VERTEX_NUM;

      VERTEX_NUM = 8;

      function Circle(vertexNumber, radius) {
        var i, rad, rot, x, y;
        this.radius = radius;
        this.update = __bind(this.update, this);
        this.curvePointEach = __bind(this.curvePointEach, this);
        this.at = __bind(this.at, this);
        rot = 360.0 / vertexNumber;
        this.points = (function() {
          var _i, _ref, _results;
          _results = [];
          for (i = _i = 0; 0 <= vertexNumber ? _i < vertexNumber : _i > vertexNumber; i = 0 <= vertexNumber ? ++_i : --_i) {
            rad = Math.PI * rot * i / 180;
            _ref = [this.radius * Math.cos(rad), this.radius * Math.sin(rad)], x = _ref[0], y = _ref[1];
            _results.push(new Point(x, y));
          }
          return _results;
        }).call(this);
      }

      Circle.prototype.at = function(idx) {
        idx = idx % this.points.length;
        if (idx < 0) {
          idx += this.points.length;
        }
        return this.points[idx];
      };

      Circle.prototype.curvePointEach = function(callback) {
        var i, point, _i, _len, _ref, _results;
        _ref = this.points;
        _results = [];
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          point = _ref[i];
          _results.push(callback(point, point.getCenter(this.at(i + 1))));
        }
        return _results;
      };

      Circle.prototype.update = function(fix, pow) {
        var point, _i, _len, _ref, _results;
        _ref = this.points;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          point = _ref[_i];
          _results.push(point.update());
        }
        return _results;
      };

      return Circle;

    })();
    WarpCircle = (function(_super) {
      __extends(WarpCircle, _super);

      function WarpCircle(circle, level, angularVelocity) {
        var point;
        this.circle = circle;
        this.points = (function() {
          var _i, _len, _ref, _results;
          _ref = this.circle.points;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            point = _ref[_i];
            _results.push(new WarpPoint(point, level, angularVelocity));
          }
          return _results;
        }).call(this);
      }

      return WarpCircle;

    })(Circle);
    ScrollCircle = (function(_super) {
      __extends(ScrollCircle, _super);

      function ScrollCircle(circle, spring, friction) {
        var point;
        this.circle = circle;
        this.onScroll = __bind(this.onScroll, this);
        this.points = (function() {
          var _i, _len, _ref, _results;
          _ref = this.circle.points;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            point = _ref[_i];
            _results.push(new VelocityPoint(point, spring, friction));
          }
          return _results;
        }).call(this);
        ScrollSensor.getInstance().events.add(this.onScroll);
      }

      ScrollCircle.prototype.onScroll = function(diff) {
        var idx, point, pow, _i, _len, _ref, _results;
        if (diff === 0) {
          return;
        }
        diff *= 0.0018;
        _ref = this.points;
        _results = [];
        for (idx = _i = 0, _len = _ref.length; _i < _len; idx = ++_i) {
          point = _ref[idx];
          if (diff < 0) {
            pow = diff * point.y() / 100;
            if (idx === 2) {
              pow *= 2.6;
            }
            pow -= 0.1;
          } else {
            pow = diff * (190 - point.y()) / 100;
            if (idx === 6) {
              pow *= 2.6;
            }
            pow += 0.1;
          }
          _results.push(point.vY -= pow);
        }
        return _results;
      };

      return ScrollCircle;

    })(Circle);
    FlickCircle = (function(_super) {
      __extends(FlickCircle, _super);

      function FlickCircle(circle, $el, spring, friction) {
        var height, point, width, _ref;
        this.circle = circle;
        this.$el = $el;
        this.flick = __bind(this.flick, this);
        this.onMouseOver = __bind(this.onMouseOver, this);
        this.onMouseMove = __bind(this.onMouseMove, this);
        _ref = [this.$el.width(), this.$el.height()], width = _ref[0], height = _ref[1];
        this.offset = {
          x: width * 0.5,
          y: height * 0.5
        };
        this.points = (function() {
          var _i, _len, _ref1, _results;
          _ref1 = this.circle.points;
          _results = [];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            point = _ref1[_i];
            _results.push(new VelocityPoint(point, spring, friction));
          }
          return _results;
        }).call(this);
        this.prevMouse = null;
        this.$el.on("mousemove", _.throttle(this.onMouseMove, 0.03));
        this.$el.on("mouseover", this.onMouseOver);
      }

      FlickCircle.prototype.onMouseMove = function(e) {
        var mouse, rect;
        rect = e.target.getBoundingClientRect();
        mouse = {
          x: e.clientX - rect.left - this.offset.x,
          y: e.clientY - rect.top - this.offset.y
        };
        if (this.prevMouse != null) {
          this.flick(mouse);
        }
        return this.prevMouse = mouse;
      };

      FlickCircle.prototype.onMouseOver = function(e) {
        return this.prevMouse = null;
      };

      FlickCircle.prototype.flick = function(mouse) {
        var cross, dist, i, mv, mvStrength, next, now, point, pow, res, v, _i, _len, _ref, _results;
        mv = Geometry.sub(mouse, this.prevMouse);
        res = (function() {
          var _i, _len, _ref, _results;
          _ref = this.points;
          _results = [];
          for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
            now = _ref[i];
            next = this.at(i + 1);
            _results.push(Geometry.isIntersection(now, next, this.prevMouse, mouse));
          }
          return _results;
        }).call(this);
        if (_.any(res)) {
          cross = Geometry.intersectionPoint(now, next, this.prevMouse, mouse);
          mvStrength = Geometry.length(mv);
          if (mvStrength < 0.5) {
            mv = Geometry.multi(mv, 0.5 / mvStrength);
          }
          if (mvStrength > 3.5) {
            mv = Geometry.multi(mv, 3.5 / mvStrength);
          }
          _ref = this.points;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            point = _ref[_i];
            v = Geometry.sub(cross, point);
            dist = Geometry.length(v);
            pow = 10 / dist;
            if (pow < 0.2) {
              pow = 0.2;
            }
            if (1 < pow || _.isNaN(dist)) {
              pow = 1;
            }
            point.vX += pow * mv.x;
            _results.push(point.vY += pow * mv.y);
          }
          return _results;
        }
      };

      return FlickCircle;

    })(Circle);
    Point = (function() {
      function Point(myX, myY) {
        this.myX = myX;
        this.myY = myY;
        this.getCenter = __bind(this.getCenter, this);
        this.y = __bind(this.y, this);
        this.x = __bind(this.x, this);
        this.update = __bind(this.update, this);
      }

      Point.prototype.update = function() {};

      Point.prototype.x = function() {
        return this.myX + (this.point != null ? this.point.x() : 0);
      };

      Point.prototype.y = function() {
        return this.myY + (this.point != null ? this.point.y() : 0);
      };

      Point.prototype.getCenter = function(other) {
        return {
          x: (this.x() + other.x()) * 0.5,
          y: (this.y() + other.y()) * 0.5
        };
      };

      return Point;

    })();
    WarpPoint = (function(_super) {
      __extends(WarpPoint, _super);

      function WarpPoint(point, level, angularVelocity) {
        this.point = point;
        this.level = level;
        this.update = __bind(this.update, this);
        this.myX = this.myY = 0;
        this.theta = {
          x: 0,
          y: 0
        };
        this.addTheta = {
          x: Math.random() * angularVelocity - angularVelocity * 0.5,
          y: Math.random() * angularVelocity - angularVelocity * 0.5
        };
        this.warp = Math.random() * 24 - 12;
      }

      WarpPoint.prototype.update = function() {
        this.point.update();
        this.theta = Geometry.add(this.theta, this.addTheta);
        this.myX = this.warp * Math.sin(this.theta.x) * this.level;
        return this.myY = this.warp * Math.cos(this.theta.y) * this.level;
      };

      return WarpPoint;

    })(Point);
    VelocityPoint = (function(_super) {
      __extends(VelocityPoint, _super);

      function VelocityPoint(point, spring, friction) {
        this.point = point;
        this.spring = spring;
        this.friction = friction;
        this.update = __bind(this.update, this);
        this.vX = this.vY = 0;
        this.myX = this.myY = 0;
      }

      VelocityPoint.prototype.update = function() {
        this.point.update();
        this.myX += this.vX = (this.vX - this.myX * this.spring) * this.friction;
        return this.myY += this.vY = (this.vY - this.myY * this.spring) * this.friction;
      };

      return VelocityPoint;

    })(Point);
    PreloadImage = (function() {
      function PreloadImage(src) {
        this.src = src;
        this._onLoad = __bind(this._onLoad, this);
        this.promise = __bind(this.promise, this);
        this._dfd = new $.Deferred;
        this.img = new Image;
        this.img.onload = this._onLoad;
        this.img.src = this.src;
      }

      PreloadImage.prototype.promise = function() {
        return this._dfd.promise();
      };

      PreloadImage.prototype._onLoad = function() {
        return this._dfd.resolve(this.img);
      };

      return PreloadImage;

    })();
    Singleton = function(klass) {
      var getInstance, instance,
        _this = this;
      instance = null;
      getInstance = function() {
        return instance != null ? instance : instance = new klass;
      };
      return {
        getInstance: getInstance
      };
    };
    ScrollSensor = (function() {
      var InnerScrollSensor;
      InnerScrollSensor = (function() {
        function InnerScrollSensor() {
          this.onScroll = __bind(this.onScroll, this);
          this.events = $.Callbacks();
          this.$win = $(window);
          this.$win.on("scroll", _.throttle(this.onScroll, 50));
        }

        InnerScrollSensor.prototype.onScroll = function(e) {
          var diff, now;
          now = this.$win.scrollTop();
          if (this.prev == null) {
            this.prev = now;
          }
          diff = now - this.prev;
          this.events.fire(diff);
          return this.prev = now;
        };

        return InnerScrollSensor;

      })();
      return Singleton(InnerScrollSensor);
    })();
    Timer = (function() {
      var InnerTimer;
      InnerTimer = (function() {
        var TIME;

        TIME = 1000.0 / 60;

        function InnerTimer() {
          this.remove = __bind(this.remove, this);
          this.add = __bind(this.add, this);
          this.emit = __bind(this.emit, this);
          this.stop = __bind(this.stop, this);
          this.start = __bind(this.start, this);
          this.list = [];
          this.start();
        }

        InnerTimer.prototype.start = function() {
          this.emit();
          return this.id = setTimeout(this.start, TIME);
        };

        InnerTimer.prototype.stop = function() {
          return clearTimeout(this.id);
        };

        InnerTimer.prototype.emit = function() {
          var elem, _i, _len, _ref, _results;
          _ref = this.list;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            elem = _ref[_i];
            _results.push(elem.update());
          }
          return _results;
        };

        InnerTimer.prototype.add = function(elem) {
          return this.list.push(elem);
        };

        InnerTimer.prototype.remove = function(elem) {
          return this.list = _.without(this.list, elem);
        };

        return InnerTimer;

      })();
      return Singleton(InnerTimer);
    })();
    Geometry = (function() {
      var add, cross, dot, iih, length, multi, sub;
      return {
        length: length = function(v) {
          var x, y, _ref;
          _ref = [_.result(v, "x"), _.result(v, "y")], x = _ref[0], y = _ref[1];
          return Math.sqrt(x * x + y * y);
        },
        add: add = function(a, b) {
          return {
            x: _.result(a, "x") + _.result(b, "x"),
            y: _.result(a, "y") + _.result(b, "y")
          };
        },
        sub: sub = function(a, b) {
          return {
            x: _.result(a, "x") - _.result(b, "x"),
            y: _.result(a, "y") - _.result(b, "y")
          };
        },
        multi: multi = function(v, m) {
          return {
            x: _.result(v, "x") * m,
            y: _.result(v, "y") * m
          };
        },
        dot: dot = function(a, b) {
          return _.result(a, "x") * _.result(b, "x") + _.result(a, "y") * _.result(b, "y");
        },
        cross: cross = function(a, b) {
          return _.result(a, "x") * _.result(b, "y") - _.result(a, "y") * _.result(b, "x");
        },
        isIntersectionHalf: iih = function(start, end, o1, o2) {
          var a, b, v;
          v = sub(end, start);
          a = sub(o1, start);
          b = sub(o2, start);
          return 0 <= dot(v, a) && 0 <= dot(v, b) && cross(v, a) * cross(v, b) <= 0;
        },
        isIntersection: function(start1, end1, start2, end2) {
          return iih(start1, end1, start2, end2) && iih(end1, start1, start2, end2);
        },
        intersectionPoint: function(start1, end1, start2, end2) {
          var d1, d2, t, v;
          v = sub(end2, start2);
          d1 = cross(v, sub(start1, start2));
          d2 = cross(v, sub(start2, start2));
          t = d1 / (d1 + d2);
          return add(start2, multi(v, t));
        }
      };
    })();
    return $.fn.extend({
      poyon: function(options) {
        var $dom, dom, _i, _len, _results;
        if (options == null) {
          options = {};
        }
        _results = [];
        for (_i = 0, _len = this.length; _i < _len; _i++) {
          dom = this[_i];
          $dom = $(dom);
          if ($.data($dom, "floatCanvas") == null) {
            _results.push($.data($dom, "floatCanvas", dom.getContext != null ? new Poyon($dom, options) : "This browser cannot use CANVAS function in html5."));
          } else {
            _results.push(void 0);
          }
        }
        return _results;
      }
    });
  })(jQuery);

}).call(this);
