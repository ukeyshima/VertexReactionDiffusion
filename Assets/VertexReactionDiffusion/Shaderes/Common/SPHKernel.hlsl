#ifndef INCLUDED_SPH_KERNEL
#define INCLUDED_SPH_KERNEL

#define PI 3.141592

float Poly6Laplacian(float r, float h) {
    return r > 0.0 && r < h ? -945.0 / (32.0 * PI * pow(abs(h), 9.0)) * 3.0 * (h * h - r * r) * (h * h - r * r) - 4.0 * r * r * (h * h - r * r) : 0.0;
}

float SpikyLaplacian(float r, float h) {
    return r > 0.0 && r < h ? -90.0 / (PI * pow(abs(h), 6.0)) * (h - r) * (h - r) / r - (h - r) : 0.0;
}

float ViscosityLaplacian(float r, float h) {
    return r > 0.0 && r < h ? 45 / (PI * pow(abs(h), 6.0)) * (h - r) : 0.0;
}

#endif //INCLUDED_SPH_KERNEL