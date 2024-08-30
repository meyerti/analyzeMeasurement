//---------------------------------------------------------------------------
#include "mex.h"
#define MY_LCC
#define MY_NO_FFT			 // used by myFIT_FUN_C2.hpp
#include "myFIT_FUN.hpp"  //#include <math.h> #include <stdio.h> #include <stdlib.h>
//---------------------------------------------------------------------------
#define SQRT_2_PI 2.5066282746310005024157652848108
#
static double dPId2       = 1.5707963267948966192313216916398;
double *gl_pFit;
//---------------------------------------------------------------------------
double myPower(const double x, const double y){
    // x^y
    return exp(y*log(x));
}
//int glN;
//---------------------------------------------------------------------------
//      User Define Function
//      Y = A4 Sin[ pi/2 (A1 - X ) /(A1-A2)]^A6, if X > A1  && X <= A2
//        = A4 Cos[ pi/2 (A2 - X ) /(A2-A3)]^A7, if X > A2  && X <= A3
//        = 0;
//      dy/dA1 =  pi/2 A4 A6 (X - A2)/(A1-A2) Sin[ ~ ]^A6 Cos[~]/Sin[~] / (A1 - A2)
//      dy/dA1 =  0
//             =  0
//      dy/dA2 =  pi/2 A4 A6 (A1 - X)/(A1-A2) Sin[ ~ ]^A6 Cos[~]/Sin[~] / (A1 - A2)
//      dy/dA2 =  pi/2 A4 A7 (X - A3)/(A2-A3) Cos[ ~ ]^A7 Sin[~]/Cos[~] / (A2 - A3)
//             =  0
//      dy/dA3 =  0
//      dy/dA3 =  pi/2 A4 A7 (A2 - X)/(A2-A3) Cos[ ~ ]^A7 Sin[~]/Cos[~] / (A2 - A3)
//             =  0
//      dy/dA4 = Sin[ pi/2 (A1 - X ) /(A1-A2)]^A6
//      dy/dA4 = Cos[ pi/2 (A2 - X ) /(A2-A3)]^A7
//      dy/dA4 = 0;
//
//      dy/dA5 = 1;
//
//      dy/dA6 = A4 log[ Sin[ pi/2 (A1 - X ) /(A1-A2)]  ] Sin[ pi/2 (A1 - X ) /(A1-A2)]^A6
//      dy/dA6 = 0;
//      dy/dA6 = 0;
//
//      dy/dA7 = 0;
//      dy/dA7 = A4 log[ Cos[ pi/2 (A2 - X ) /(A2-A3)]  ] Cos[ pi/2 (A2 - X ) /(A2-A3)]^A7
//      dy/dA7 = 0;
//
//		para[0-6]=A1 A2 A3 A4 A5 A6 A7;
//---------------------------------------------------------------------------
void myHeart_Fit_v0b(double x, double *para, double *y, double *dyda, int na){
    double dtmpA, dtmpB, dtmpC, dtmpD, dtmpP;
    *y=para[4]; dyda[4]=1;
    if(x<=para[0]){ // <=A1
        dyda[0]=dyda[1]=dyda[2]=dyda[3]=dyda[5]=dyda[6]=0;
    }else if(x<=para[1]){ // (A1, A2]
        dtmpB = (dtmpA = para[0] - x) * dPId2 * (dtmpC = 1/ (para[0]-para[1]) ); // dtmpB > 0
        dtmpD = sin(dtmpB);
        // A4 Sin[ pi/2 (A1 - X ) /(A1-A2)]^A6, if X > A1  && X <= A2
        *y+= (dyda[3] = myPower(dtmpD,para[5])) * para[3]; //if (glN==0){glN++; printf("y=%f, dtmpB=%f\n",y, dtmpB);}
        // pi/2 A4 A6 (X - A2)/(A2-A1) Sin[ ~ ]^A6 Cos[~]/Sin[~] / (A2 - A1)
        dyda[0]= (dtmpB = para[3] * para[5] * dPId2 * dtmpC * dtmpC * dyda[3]* cos(dtmpB) / dtmpD )*(x - para[1]);
        dyda[1]= dtmpB * dtmpA;
        dyda[2]=0;
        dyda[5]= para[3]*log(dtmpD)*dyda[3];
        dyda[6]=0;
    }else if(x<= para[2]){ // (A2, A3]
        //      Y  =  A4 Cos[ pi/2 (A2 - X ) /(A2-A3)]^A7, if X > A2  && X <= A3
        //      dy/dA1 =  0
        //      dy/dA2 =  pi/2 A4 A7 (X - A3)/(A2-A3) Cos[ ~ ]^A7 Sin[~]/Cos[~] / (A2 - A3)
        //      dy/dA3 =  pi/2 A4 A7 (A2 - X)/(A2-A3) Cos[ ~ ]^A7 Sin[~]/Cos[~] / (A2 - A3)
        //      dy/dA4 = Cos[ pi/2 (A2 - X ) /(A3-A2)]^A7
        
        dtmpB = (dtmpA = para[1] - x) * dPId2 * (dtmpC = 1/ (para[2]-para[1]));  // dtmpB > 0
        dtmpD = cos(dtmpB);
        *y+= (dyda[3] = myPower(dtmpD,para[6])) * para[3]; //if (glN==1){glN++; printf("y=%f, dtmpB=%f\n",y, dtmpB);}
        dyda[0] = 0;
        dyda[1] = (dtmpB = para[3] * para[6] * dPId2 * dtmpC * dtmpC * dyda[3]* sin(dtmpB) / dtmpD )*(x - para[2]);
        dyda[2] = dtmpB * dtmpA;
        dyda[5] = 0;
        dyda[6] = para[3]*log(dtmpD)*dyda[3];
    }else{
        dyda[0]=dyda[1]=dyda[2]=dyda[3]=dyda[5]=dyda[6]=0;
    }
    //printf("x=%f, y=%f,dyda=%f,%f,%f,%f,%f,%f,%f\n",x,*y,dyda[0],dyda[1],dyda[2],dyda[3],dyda[4],dyda[5],dyda[6]);
    
}
//---------------------------------------------------------------------------
void __fastcall myRangeCheck(const int n, const double d1, const double d2, double &d, const double *p){
    if((n&1)>0){
        if(d<d1)d=d1;
    }else if((n&4)>0){
        int nd1=d1;
        if(d<p[nd1])d=p[nd1];
    }
    if((n&2)>0){
        if(d>d2)d=d2;
    }else if((n&8)>0){
        int nd2=d2;
        if(d>p[nd2])d=p[nd2];
    }
    //printf("%d, %f,%f, %f\n",n, d1,d2, d);
}
void myHeart_Fit_v0b_Range(double *para, int ma, int *ia, int mfit){
    int i=0;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    //if(para[0]<=1e-17)para[0]=1e-17;  // A1 = E
    i=1;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    if((ia[i]!=2&&ia[i]!=4&&ia[i]!=5&&ia[i]!=13)&&para[1]<=1e-17)para[1]=para[0]+1e-17;  // A2 shall be >A1
    i=2;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    if((ia[i]!=2&&ia[i]!=4&&ia[i]!=5&&ia[i]!=13)&&para[2]<=1e-17)para[2]=para[1]+1e-17;  // A3 shall be >A2
    //if(para[2]<=-1e+17)para[2]=-1e+17;
    i=3;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    i=4;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    i=5;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    if((ia[i]!=2&&ia[i]!=4&&ia[i]!=5&&ia[i]!=13)&&para[5]<=1e-17)para[5]=1e-7;           // A6 shall be >0
    i=6;
    if(ia[i]>1)myRangeCheck(ia[i]-1,gl_pFit[i+7],gl_pFit[i+7+7],para[i],para);
    if((ia[i]!=2&&ia[i]!=4&&ia[i]!=5&&ia[i]!=13)&&para[6]<=1e-17)para[6]=1e-7;           // A7 shall be >0
}
// void myHeart_Fit_v0b_Range(double *para, int ma, int *ia, int mfit){
//     //if(para[0]<=0)para[0]=1e-17;  // A1 = E
//     if(para[1]<=para[0])para[1]=para[0]+1e-17;  // A2 shall be >A1
//     if(para[2]<=para[1])para[2]=para[1]+1e-17;  // A3 shall be >A2
//     if(para[5]<=1e-7   )para[5]=1e-7;           // A6 shall be >0
// }
//---------------------------------------------------------------------------
#ifndef MY_LCC
//---------------------------------------------------------------------------
//#pragma argsused
//int WINAPI DllEntryPoint(HINSTANCE hinst, unsigned long reason, void* lpReserved)
//{
//        return 1;
//}
//---------------------------------------------------------------------------
void _export  mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
#else
[pFitErr   mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
#endif
{
    
    double *xData, *yData, *sigData, *sigData0=NULL;
    double pFit[8], *pFitA, *pFitA_fit, *pFitErr=NULL;
    int nCountD , nCountA, nFit_fit[8], i=0, j;
    bool bError=false, bWeight=false;
    double *ppCovar[8], pCovar[64], *ppAlpha[8], pAlpha[64];
    double dChisq, dAlamda;
    
    while(1){
        if (4>nrhs||6<nrhs){bError=true; break;}
        
        // start to get the matlab data and check the size
        nCountD = mxGetN(prhs[i]) * mxGetM(prhs[i]);                  // X length
        xData = (double *) mxGetData(prhs[i++]);
        
        if(nCountD > mxGetN(prhs[i]) * mxGetM(prhs[i]))bError=true;  // Y length >= X
        
        yData = (double *) mxGetData(prhs[i++]);
        //if(nCountD == mxGetN(prhs[i]) * mxGetM(prhs[i])){  // W length = X,Y
        //    sigData = (double *) mxGetData(prhs[i++]); bWeight=true;
        //}
        nCountA = mxGetN(prhs[i]) * mxGetM(prhs[i]);
        if(nCountA<7) {bError=true; break;}             // 7 para
        nCountA = 7;
        pFitA  = (double *) mxGetData(prhs[i++]);                    // para
        if (nrhs<=i){bError=true; break;}
        if(nCountA > mxGetN(prhs[i]) * mxGetM(prhs[i]))bError=true;
        pFitA_fit= (double *) mxGetData(prhs[i++]);gl_pFit = pFitA_fit;                 // Fitting para
        if (nrhs>i){
            if(nCountA > mxGetN(prhs[i]) * mxGetM(prhs[i]))bError=true; // Error return
            pFitErr = (double *) mxGetData(prhs[i++]);
        }
        if (nrhs>i){
            if(nCountD > mxGetN(prhs[i]) * mxGetM(prhs[i]))bError=true;  // Y length >= X
            sigData0 = (double *) mxGetData(prhs[i++]);
        }
        break;
    }
    if(bError) mexErrMsgTxt("Using: [chi,Count]= myHeart_fit_vf(X, Y, A, F[, E, W]); E is error output and can be skip if one do not need\n"\
            "A=[T1, T2, T3, Amp, Offset, Power1, Power2], F is fit switch, 0 = no fix, 1 fit with default boarder,\nif any F is 2(check low),3(check high),4(both), 9 link with the next value as index, F(:,[2,3]) will be the low and high boarder or index.");
    //glN=0;
    
    UserDef_funcs = myHeart_Fit_v0b; UserDef_Rage = myHeart_Fit_v0b_Range; // select our fit and rang-check function
    plhs[0] = mxCreateDoubleMatrix(1 , 1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(1 , 1, mxREAL);
    if (sigData0==NULL)
        sigData = new double [nCountD];
    else sigData = sigData0;
    if (sigData!=NULL){
        if (sigData0==NULL)
            for(i=0;i<nCountD;i++)sigData[i] = 1;  // here we use same priority for all the data
        for(int i=0; i<nCountA; i++){  // generate our working place and copy data
            ppCovar[i]=&(pCovar[i*nCountA]);
            ppAlpha[i]=&(pAlpha[i*nCountA]);
            nFit_fit[i] = pFitA_fit[i];
            pFit[i] = pFitA[i];
        }
        
        j = MyMrqmin(xData, yData, sigData, nCountD, pFit, nFit_fit, nCountA,
                ppCovar, ppAlpha, &dChisq, &dAlamda);  // Doing fit
        
        *(mxGetPr(plhs[1]))= j;
        
        if(pFitErr!=NULL)
            for(i=0, j = nCountD - nCountA; i<nCountA; i++){   // Save data and error matrix to matlab
                pFitA[i] = pFit[i];
                if(nFit_fit[i]!=0 && j>0) pFitErr[i] = sqrt( fabs( dChisq * ppCovar[i][i]/j) );
                else pFitErr[i] = 0;
            }
        
        *(mxGetPr(plhs[0]))= dChisq;  // return model error to matlab
        if (sigData != sigData0)
            delete[] sigData;
    }
}
//---------------------------------------------------------------------------
// mex -O -output myHeart_fit_vfb3 myHeart_fit_vfb3.cpp
//mex COPTIMFLAGS='-O2 -DNDEBUG' -O -output myHeart_fit_vfb3 myHeart_fit_vfb3.cpp
