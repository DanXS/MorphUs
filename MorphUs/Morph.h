//
//  Morph.h
//  MorphUs
//
//  Created by Dan Shepherd on 06/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//
#pragma once

#ifndef MorphUs_Morph_h
#define MorphUs_Morph_h



#include <vector>
#include "Matrix.h"

using namespace std;

typedef Matrix<double> dmatrix;

typedef pair<double, double> Marker;

class Morph
{
private:
    int nMarkers;
    int nWeights;
    vector<Marker> srcMarkers;
    vector<Marker> destMarkers;
    vector<Marker> interpMarkers;
    dmatrix* pLInv;
    double TPS(double xi, double yi, double xj, double yj);
    void CalcL(dmatrix& L, vector<Marker> &markers);
    void CalcY(dmatrix& Y, vector<Marker> &markers);
    dmatrix backwardMap(dmatrix Inv, dmatrix& Y);
public:
    Morph();
    ~Morph();
    void ClearMarkers();
    void AddSrcMarker(double x, double y);
    void AddDestMarker(double x, double y);
    void BuildMatrices();
    bool Interpolate(double alpha);
    int GetWeightCount();
    void GetSrcWeights(float* dest);
    void GetDestWeights(float* dest);
    void GetInterpolatedMarkers(float* dest);
};

#endif
