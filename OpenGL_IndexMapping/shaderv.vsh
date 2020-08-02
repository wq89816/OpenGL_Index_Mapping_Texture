
attribute vec4 position;
attribute vec4 positionColor;
attribute vec2 textCoord;



uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec4 varyColor;
varying lowp vec2 varyTextCoord;

void main()
{
    varyColor = positionColor;
    varyTextCoord = textCoord;

    vec4 vPos;

        //4*4 * 4*4 * 4*1
    vPos = projectionMatrix * modelViewMatrix * position;

        //ERROR
        //vPos = position * modelViewMatrix  * projectionMatrix ;
    gl_Position = vPos;
}
