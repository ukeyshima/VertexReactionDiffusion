#ifndef INCLUDED_SPH_KERNEL
#define INCLUDED_SPH_KERNEL

#define PI 3.141592

float Poly6(float r, float h) {
    return r > 0.0 && r <= h ? 315.0 / (64.0 * PI * pow(abs(h), 9.0)) * (h * h - r * r) * (h * h - r * r) * (h * h - r * r) : 0.0;
}

float Poly6Laplacian(float r, float h) {
    return r > 0.0 && r < h ? -945.0 / (32.0 * PI * pow(abs(h), 9.0)) * 3.0 * (h * h - r * r) * (h * h - r * r) - 4.0 * r * r * (h * h - r * r) : 0.0;
}

float SpikyLaplacian(float r, float h) {
    return r > 0.0 && r < h ? -90.0 / (PI * pow(abs(h), 6.0)) * (h - r) * (h - r) / r - (h - r) : 0.0;
}

float ViscosityLaplacian(float r, float h) {
    return r > 0.0 && r < h ? 45 / (PI * pow(abs(h), 6.0)) * (h - r) : 0.0;
}

float CubicSpline(float r, float h)
{
    float q = abs(r) / h;
    float a = 1 / (PI * h * h * h);
    return a * (q > 0.0 && q < 1.0
                    ? 1 - 3 / 2 * q * q + 3 / 4 * q * q * q
                    : q >= 1.0 && q < 2.0
                    ? 1 / 4 * pow(2 - q, 3)
                    : 0.0);
}

#endif //INCLUDED_SPH_KERNEL