precision mediump float;

uniform float time;
uniform vec2 resolution;
uniform float fractalIncrementer;

#define NEAR 0.0
#define FAR 100.0
#define EPSILON 0.0001
#define MAX_STEPS 150
#define POWER 0.0

mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

mat3 rotateZ(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, -s, 0),
        vec3(s, c, 0),
        vec3(0, 0, 1)
    );
}

float FractalDistance(vec3 point) 
{
    vec3 z = point;
    float dr = 3.0;
    float r;

    for(int i = 0; i < 30; i++)
    {
        r = length(z);
        if(r > 3.0)
        {
            break;
        }

        float power = POWER + fractalIncrementer;
        float theta = acos(z.z / r) * power;
        float phi = atan(z.y, z.x) * power;
        float zr = pow(r, power);
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        
        z = zr * vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
        z += point;
    }

    return (0.5 * log(r) * r) / dr;
}

float sceneSDF(vec3 point)
{
    point = rotateZ(time) * rotateX(time) * rotateY(time) * point;
    return FractalDistance(point);
}

float rayMarch(vec3 rayOrigin, vec3 raydrection)
{
    float totalDistance = 0.0;
    int steps;

    for(int i = 0; i < MAX_STEPS; i++)
    {
        steps = i;
        vec3 point = rayOrigin + totalDistance * raydrection;
        float dist = sceneSDF(point);
        totalDistance += dist;

        if(dist < EPSILON)
        {
            break;
        }

        if(dist > FAR)
        {
            steps = MAX_STEPS;
            break;
        }
    }

    return 1.0 - (float(steps) / float(MAX_STEPS));
}

mat3 viewMatrix(vec3 eye, vec3 center, vec3 up) {
	vec3 f = normalize(center - eye);
	vec3 s = normalize(cross(f, up));
	vec3 u = cross(s, f);
	return mat3(s, u, -f);
}

vec3 raydrection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

void main()
{
    vec3 eyePosition = vec3(5.0, 5.0, 5.0);
    vec3 drectionOfRay = raydrection(45.0, resolution.xy, gl_FragCoord.xy);
    mat3 rayTransform = viewMatrix(eyePosition, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));

    vec3 worlddrection = rayTransform * drectionOfRay;

    float greyScale = rayMarch(eyePosition, worlddrection);

    gl_FragColor = vec4(greyScale, greyScale, greyScale, 1.0);
}