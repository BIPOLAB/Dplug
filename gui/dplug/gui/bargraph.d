/**
* Copyright: Copyright Auburn Sounds 2015 and later.
* License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
* Authors:   Guillaume Piolat
*/
module dplug.gui.bargraph;

import std.math;
import dplug.gui.element;
import dplug.core.unchecked_sync;
import dplug.core;

// Vertical bargraphs made of LEDs
class UIBargraph : UIElement
{
public:

    struct LED
    {
        RGBA diffuse;
    }

    /// Creates a new bargraph.
    /// [minValue .. maxValue] is the interval of values that will span [0..1] once remapped.
    this(UIContext context, int numChannels, float minValue, float maxValue,
         int redLeds = 3, int orangeLeds = 3, int yellowLeds = 3, int greenLeds = 9)
    {
        super(context);

        _values.length = numChannels;
        _values[] = 0;

        _minValue = minValue;
        _maxValue = maxValue;

        foreach (i; 0..redLeds)
            _leds ~= LED(RGBA(255, 32, 0, 255));

        foreach (i; 0..orangeLeds)
            _leds ~= LED(RGBA(255, 128, 64, 255));

        foreach (i; 0..yellowLeds)
            _leds ~= LED(RGBA(255, 255, 64, 255));

        foreach (i; 0..greenLeds)
            _leds ~= LED(RGBA(32, 255, 16, 255));

         _valueMutex = new UncheckedMutex();
    }

    override void close()
    {
        _valueMutex.close();
    }


    override void onDraw(ImageRef!RGBA diffuseMap, ImageRef!L16 depthMap, ImageRef!RGBA materialMap, box2i[] dirtyRects)
    {
        // TODO fill material map
        depthMap.fill(L16(59));
        diffuseMap.fill(RGBA(64, 64, 64, 0));

        int numLeds = cast(int)_leds.length;
        int numChannels = cast(int)_values.length;
        int width = _position.width;
        int height = _position.height;
        float border = width * 0.06f;

        box2f available = box2f(border, border, width - border, height - border);

        float heightPerLed = cast(float)(available.height) / cast(float)numLeds;
        float widthPerLed = cast(float)(available.width) / cast(float)numChannels;

        float tolerance = 1.0f / numLeds;

        foreach(channel; 0..numChannels)
        {
            float value = getValue(channel);
            float x0 = border + widthPerLed * (channel + 0.15f);
            float x1 = x0 + widthPerLed * 0.7f;

            foreach(i; 0..numLeds)
            {
                float y0 = border + heightPerLed * (i + 0.1f);
                float y1 = y0 + heightPerLed * 0.8f;

                depthMap.aaFillRectFloat!false(x0, y0, x1, y1, L16(60));

                float ratio = 1 - i / cast(float)(numLeds - 1);

                ubyte shininess = cast(ubyte)(0.5f + 255.0f * (1 - smoothStep(value - tolerance, value, ratio)));

                RGBA color = _leds[i].diffuse;
                color.r = (color.r * (255 + shininess) + 255) / 510;
                color.g = (color.g * (255 + shininess) + 255) / 510;
                color.b = (color.b * (255 + shininess) + 255) / 510;
                color.a = shininess;
                diffuseMap.aaFillRectFloat!false(x0, y0, x1, y1, color);

            }
        }
    }

    void setValues(float[] values) nothrow @nogc
    {
        {
            _valueMutex.lock();
            scope(exit) _valueMutex.unlock();
            assert(values.length == _values.length);

            // remap all values
            foreach(i; 0..values.length)
            {
                _values[i] = linmap!float(values[i], _minValue, _maxValue, 0, 1);
                _values[i] = clamp!float(_values[i], 0, 1);
            }
        }
        setDirty();
    }

    float getValue(int channel) nothrow @nogc
    {
        _valueMutex.lock();
        scope(exit) _valueMutex.unlock();
        return _values[channel];
    }

protected:
    LED[] _leds;

    UncheckedMutex _valueMutex;
    float[] _values;
    float _minValue;
    float _maxValue;
}