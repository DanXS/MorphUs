//
//  Morph.cpp
//  MorphUs
//
//  Created by Dan Shepherd on 06/07/2014.
//  Copyright (c) 2014 cuffedtothekeyboard. All rights reserved.
//

#include <iostream>
#include "Morph.h"

using namespace std;

Morph::Morph()
{
    this->pLInv = NULL;
    this->nWeights = 0;
    this->ClearMarkers();
}

Morph::~Morph()
{
    if(this->pLInv != NULL) {
        delete this->pLInv;
        this->pLInv = NULL;
    }
    this->ClearMarkers();
}

void Morph::ClearMarkers()
{
    this->srcMarkers.clear();
    this->destMarkers.clear();
    this->interpMarkers.clear();
}

void Morph::AddSrcMarker(double x, double y)
{
    this->srcMarkers.push_back(Marker(x, y));
}

void Morph::AddDestMarker(double x, double y)
{
    this->destMarkers.push_back(Marker(x, y));
}

bool Morph::Interpolate(double alpha)
{
    if(this->srcMarkers.size() > 0 && this->srcMarkers.size() == this->destMarkers.size())
    {
        this->interpMarkers.clear();
        for(int i = 0; i < this->srcMarkers.size(); i++) {
            double x = (1.0f-alpha) * this->srcMarkers[i].first + alpha * this->destMarkers[i].first;
            double y = (1.0f-alpha) * this->srcMarkers[i].second + alpha * this->destMarkers[i].second;
            this->interpMarkers.push_back(Marker(x,y));
        }
        return true;
    }
    else
    {
        cerr << "Error: No Markers to interpolate!\n";
        return false;
    }
}

double Morph::TPS(double xi, double yi, double xj, double yj)
{
    double r2 = (xi-xj)*(xi-xj)+(yi-yj)*(yi-yj);
    if(r2<=TINY)
        return 1.0f;
    else
        return r2*log(r2);
}

void Morph::CalcL(dmatrix& L, vector<Marker> &markers)
{
    for(int i = 0; i < this->nMarkers; i++)
    {
        for(int j = i; j < this->nMarkers; j++)
        {
            double xi = markers[i].first;
            double yi = markers[i].second;
            double xj = markers[j].first;
            double yj = markers[j].second;
            double tps = TPS(xi, yi, xj, yj);
            L.Element(i, j) = tps;
            L.Element(j, i) = tps;
        }
    }
    for(int i = 0; i < this->nMarkers; i++)
    {
        L.Element(i, this->nMarkers) = 1.0f;
        L.Element(i, this->nMarkers+1) = markers[i].first;
        L.Element(i, this->nMarkers+2) = markers[i].second;
        L.Element(this->nMarkers, i) = 1.0f;
        L.Element(this->nMarkers+1, i) = markers[i].first;
        L.Element(this->nMarkers+2, i) = markers[i].second;
    }

    for(int i = 0; i < 3; i++)
    {
        for(int j = 0; j < 3; j++)
        {
            L.Element(this->nMarkers+i, this->nMarkers+j) = 0.0f;
        }
    }
}

void Morph::CalcY(dmatrix& Y, vector<Marker> &markers)
{
    for(int i = 0; i < this->nMarkers; i++)
    {
        Y.Element(i, 0) = markers[i].first;
        Y.Element(i, 1) = markers[i].second;
    }
    for(int i = 0; i < 3; i++)
    {
        Y.Element(this->nMarkers+i, 0) = 0.0f;
        Y.Element(this->nMarkers+i, 1) = 0.0f;
    }
}

void Morph::BuildMatrices()
{
    if(this->srcMarkers.size() > 0 && this->srcMarkers.size() == this->destMarkers.size())
    {
        this->nMarkers = (int)this->srcMarkers.size();
        this->nWeights = this->nMarkers+3;
        
        dmatrix* L = new dmatrix(this->nWeights, this->nWeights);
        
        this->CalcL(*L, this->interpMarkers);
        if(this->pLInv != NULL) {
            delete this->pLInv;
            this->pLInv = NULL;
        }
        this->pLInv = L;
        this->pLInv->Inverse();
    }
}

int Morph::GetWeightCount()
{
    this->nMarkers = (int)this->srcMarkers.size();
    this->nWeights = this->nMarkers+3;
    return this->nWeights;
}

dmatrix Morph::backwardMap(dmatrix Inv, dmatrix &Y)
{
    return Inv *= Y;
}

void Morph::GetSrcWeights(float* dest)
{
    dmatrix Y(this->nWeights, 2);
    this->CalcY(Y, this->srcMarkers);
    double* result = backwardMap(*this->pLInv, Y).GetContents();
    for(int i = 0; i < 2*this->nWeights; i++)
    {
        dest[i] = (float)result[i];
    }
}

void Morph::GetDestWeights(float* dest)
{
    dmatrix Y((int) this->nWeights, (int) 2);
    this->CalcY(Y, this->destMarkers);
    double* result = backwardMap(*this->pLInv, Y).GetContents();
    for(int i = 0; i < 2*this->nWeights; i++)
    {
        dest[i] = (float)result[i];
    }
}

void Morph::GetInterpolatedMarkers(float* dest)
{
    for(int i = 0; i < this->interpMarkers.size(); i++) {
        dest[2*i] = (float)this->interpMarkers[i].first;
        dest[2*i+1] = (float)this->interpMarkers[i].second;
    }
}



