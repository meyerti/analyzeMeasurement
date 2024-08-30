//---------------------------------------------------------------------------
#ifndef myFIT_FUN_hpp
#define myFIT_FUN_hpp
//---------------------------------------------------------------------------
// This version Changed MyGaussJ 
// Correct the G-J Inverse Function
// 2009.04.30 Bao Guboin
// 2009.12.11 Bao Guboin
// 2012.07.10 Correct old 2D fit, it also can be used for 1D
//---------------------------------------------------------------------------
#include <math.h>
//#include <stdio.h>
//  #include <windows.h>

//---------------------------------------------------------------------------
#define MY_MAX 27
#define MY_MAX_LAMDA 1e17
#define MY_MAX_TIMES_A    100
#define MY_MAX_TIMES_B    17

static double dM_LOG2E = 1.4426950408889634073599246810019;
static double dM_LN2 = 0.69314718055994530941723212145818;
static double dONE      = 1;
static double dPI       = 3.1415926535897932384626433832795;

static double *gl_pX2;
static int gl_nIndex_i;
//---------------------------------------------------------------------------
bool DimensionCheck(int n){
    if(n>MY_MAX){
           //MessageBox(NULL, "MAX dimention is limited!", "Error in MAX dimention",MB_OK | MB_ICONWARNING );
           return false;
    }
    return true;
}
//---------------------------------------------------------------------------
void MyGaussJ(double **a, int n, double **b, int m){
//Linear equation solution by Gauss-Jordan elimination.
//a[0..n-1][0..n-1] is the input matrix. b[0..n-1][0..m-1] is the m right-hand side vectors.
//On output, a is replaced by its matrix inverse, and b is replaced by the corresponding set
   double *fpL[MY_MAX],*fpR[MY_MAX], *pfTemp;
   int nIndex[MY_MAX],nIndexT[MY_MAX];
   int nIndeC[MY_MAX],nIndeR[MY_MAX];
   int i,j,k, l, irow, icol, iTemp;
   double fbig, fTemp;

   for(i=0;i<n;i++){
      fpL[i]=a[i]; fpR[i]=b[i];
      nIndex[i]=i; nIndexT[i]=i;
   }
   for(i=0;i<n;i++){
      fbig=fpL[i][nIndex[i]];nIndeR[i]=nIndexT[irow=i]; nIndeC[i]=nIndex[icol=i];  //fbig=0; irow = icol = i;
	  for (j=i;j<n;j++)
		 for (k=i;k<n;k++)
	   if ((fTemp=fabs(fpL[j][nIndex[k]])) > fbig){
			  fbig = fTemp;
			  nIndeR[i]=nIndexT[irow=j]; nIndeC[i]=nIndex[icol=k];
           }
      if (irow != i){
         pfTemp=fpL[irow]; fpL[irow]=fpL[i]; fpL[i]= pfTemp;
         pfTemp=fpR[irow]; fpR[irow]=fpR[i]; fpR[i]= pfTemp;
         iTemp = nIndexT[irow]; nIndexT[irow] = nIndexT[i]; nIndexT[i]= iTemp;
      }
      if (icol != i){
         iTemp = nIndex[icol]; nIndex[icol] = nIndex[i]; nIndex[i]= iTemp;
      }
      if ( (fTemp = fpL[i][nIndex[i]]) == 0.0){
         //MessageBox(NULL, "All 0 in array!", "All 0 in Array!",MB_OK | MB_ICONWARNING );
         return;
      }
      fTemp=1.0/fTemp;  fpL[i][iTemp = nIndex[i]]=1;
      for (j=0;j<n;j++) fpL[i][nIndex[j]] *= fTemp;
      for (j=0;j<m;j++) fpR[i][j] *= fTemp;
      for (j=0;j<n;j++){
         if(j==i)continue;
         fTemp = fpL[j][iTemp]; fpL[j][iTemp]=0.0;
         for (k=0;k<n;k++){
            l=nIndex[k];
            fpL[j][l] -= fpL[i][l] * fTemp;
         }
         for (k=0;k<m;k++)
            fpR[j][k] -= fpR[i][k] * fTemp;
      }
   }
   for(i=0;i<n;i++){
      nIndex[i]=i; nIndexT[i]=i;
   }
   // Until Here, we have all the data, if we donot need an inv, we can quit at this point
   // Now, we reshape the matrix to fit the real INV of the input
   for (i=0;i<n;i++){
      if((k = nIndex[nIndeR[i]])!= (l = nIndeC[i])){
         iTemp = nIndexT[l];  nIndexT[l]=nIndexT[k];  nIndexT[k]=iTemp;
         nIndex[nIndexT[l]]=l;
         nIndex[nIndexT[k]]=k;
         for (j=0;j<n;j++){
            fTemp=a[k][j]; a[k][j]=a[l][j]; a[l][j]= fTemp;
         }
         for (j=0;j<m;j++){
            fTemp=b[k][j]; b[k][j]=b[l][j]; b[l][j]= fTemp;
         }
      }
      nIndeC[i]=l;
      nIndeR[i]=k;
   }
   for (i=n-1;i>=0;i--){
      if((k = nIndeR[i])!= (l = nIndeC[i])){
         for (j=0;j<n;j++){
            fTemp=a[j][k]; a[j][k]=a[j][l]; a[j][l]= fTemp;
         }
      }
   }
}
//---------------------------------------------------------------------------
void MyGaussJ1(double **a, int n, double **b, int m){
//Help function: Linear equation solution call gate for fortran to c
// or to any Matrix that are not leading with 0 but 1 in the index
   double *fpL[MY_MAX],*fpR[MY_MAX];
   int i;
   for(i=0;i<n;i++){
      fpL[i]=&(a[i+1][1]); fpR[i]=&(b[i+1][1]);
   }
   MyGaussJ(fpL, n, fpR, m);
}
//---------------------------------------------------------------------------
void (*UserDef_funcs)(double x, double *para, double *y, double *dyda, int na);
// This is call gate for user define function
// x: incoming data point for x
//para[0] ~ para[na-1]: fit par
// y: outgoing data from the function
//dyda[0] ~ dyda[na-1]: outgoing data, the first partical derivative of each fit par
//---------------------------------------------------------------------------
void (*UserDef_Rage)(double *para, int na, int *ia, int nfit);
// This is user define range check function
//---------------------------------------------------------------------------
void MyCovsrt(double **covar, int ma, int *ia, int mfit){
//When end, we need to reshape the error matrix, if mfit != ma
   int i,j,k;
   double fTemp;
   for (i=mfit;i<ma;i++)
   for (j=0;j<i;j++) covar[i][j]=covar[j][i]=0.0;
   k=mfit-1;
   for (j=ma-1;j>=0;j--) {
   	if (ia[j]) {
   		for (i=0;i<ma;i++){
                   fTemp=covar[i][k]; covar[i][k]= covar[i][j]; covar[i][j]=fTemp;
                }
                for (i=0;i<ma;i++){
                   fTemp=covar[k][i]; covar[k][i]= covar[j][i]; covar[j][i]=fTemp;
                }
   		k--;
   	}
   }
}
//---------------------------------------------------------------------------
double MyMrqcof2(double *x, double *y, double *sig, int ndata, double *a, int *ia,
        int ma, double **alpha, double *beta ){
// This is old version which used for 1D, we leave this for checking;
// help function to calculate the Chi square and H' matrix
// For Newton way, one need to calculate again the 2ed derivative to get a full Hession matrix
int i, j, k, l, m, mfit=0;
double ymod, wt, sig2i, dy;
double fdyda[MY_MAX];
double fChisq=0;

for (j=0;j<ma;j++) if (ia[j]) mfit++;
for (j=0;j<mfit;j++) {       // Initialize a symmetric alpha, beta.
   for (k=0;k<=j;k++) alpha[j][k]=0.0;
   beta[j]=0.0;
}
for (i=0;i<ndata;i++) {      //loop over all data and cal Hession' .
   (*UserDef_funcs)(x[i], a , &ymod, fdyda, ma );
   sig2i=1.0/(sig[i]*sig[i]);
   dy=y[i]-ymod;
   for (j=0,l=0;l<ma;l++) {
      if (ia[l]) {
         wt=fdyda[l]*sig2i;
         for (k=0,m=0;m<=l;m++)
             if (ia[m])
                 alpha[j][k++] += wt*fdyda[m];
         beta[j++] += dy*wt;
      }
   }
   fChisq += dy*dy*sig2i; // Cal Chi square.
}
for (j=1;j<mfit;j++)        //We suppose a symmetric Hession'
   for (k=0;k<j;k++) alpha[k][j]=alpha[j][k];
return fChisq;
}
//---------------------------------------------------------------------------
double MyMrqcof(double *x, double *y, double *sig, int ndata, double *a, int *ia,
        int ma, double **alpha, double *beta ){
// help function to calculate the Chi square and H' matrix
// For Newton way, one need to calculate again the 2ed derivative to get a full Hession matrix
int i, j, k, l, m, mfit=0;
double ymod, wt, sig2i, dy;
double fdyda[MY_MAX];
double fChisq=0;

for (j=0;j<ma;j++) if (ia[j]) mfit++;
for (j=0;j<mfit;j++) {       // Initialize a symmetric alpha, beta.
   for (k=0;k<=j;k++) alpha[j][k]=0.0;
   beta[j]=0.0;
}
for (i=0;i<ndata;i++) {      //loop over all data and cal Hession' .
   (*UserDef_funcs)(x[(gl_nIndex_i = i)], a , &ymod, fdyda, ma );
   sig2i=1.0/(sig[i]*sig[i]);
   dy=y[i]-ymod;
   for (j=0,l=0;l<ma;l++) {
      if (ia[l]) {
         wt=fdyda[l]*sig2i;
         for (k=0,m=0;m<=l;m++)
             if (ia[m])
                 alpha[j][k++] += wt*fdyda[m];
         beta[j++] += dy*wt;
      }
   }
   fChisq += dy*dy*sig2i; // Cal Chi square.
}
for (j=1;j<mfit;j++)        //We suppose a symmetric Hession'
   for (k=0;k<j;k++) alpha[k][j]=alpha[j][k];
return fChisq;
}
//---------------------------------------------------------------------------
void MyMrqmin_1(double *x, double *y, double *sig, int ndata, double *a, int *ia,
        int ma, double **covar, double **alpha, double *chisq, double *alamda){

int j,k,l;
static int mfit;
static double ochisq, fAtry[MY_MAX], fBeta[MY_MAX], da[MY_MAX], *pOneda[MY_MAX];
double dTemp;
if (*alamda < 0.0){ // We use a 0 value to Initialize the starting point
   for (mfit=0,j=0;j<ma;j++)if (ia[j]) mfit++;
   *alamda= 1;
   *chisq = ochisq= MyMrqcof(x,y,sig,ndata,a,ia,ma,alpha, fBeta);
   for (j=0;j<ma;j++){ fAtry[j]=a[j]; pOneda[j]=&(da[j]);}
}
// Alter linearized fitting matrix, by augmenting diagonal elements.
for (j=0;j<mfit;j++) {
   for (k=0;k<mfit;k++) covar[j][k]=alpha[j][k];
#ifndef MY_LCC   
   try{
#endif
      dTemp = ((double)(alpha[j][j]))*(1.0+(*alamda));
#ifndef MY_LCC   
   }   catch(...){
      dTemp = 0;
   }
#endif
   covar[j][j]= dTemp;
   da[j]=fBeta[j];
}
MyGaussJ(covar, mfit, pOneda, 1);
if (*alamda == 0.0) {    // Once converged, evaluate covariance matrix.
   MyCovsrt(covar, ma, ia, mfit);
   if(*chisq > ochisq)*chisq= ochisq;
   return;
}
//Did the trial succeed?
for (j=0,l=0;l<ma;l++)
   if (ia[l]) fAtry[l]=a[l] + da[j++];
///////////////////////////////////////////////////////////////////////////////
(*UserDef_Rage)(fAtry, ma, ia, mfit);
///////////////////////////////////////////////////////////////////////////////
*chisq = MyMrqcof(x,y,sig,ndata,fAtry,ia,ma,covar,da);
if (*chisq < ochisq) {   // Success, accept the new solution.
  *alamda *= 0.1;
   ochisq = (*chisq);
   for (j=0;j<mfit;j++) {
      for (k=0;k<mfit;k++) alpha[j][k]=covar[j][k];
      fBeta[j]=da[j];
   }
   for (l=0;l<ma;l++) a[l]=fAtry[l];
}else{// Failure, increase alamda and return.
   *alamda *= 10;
   *chisq = ochisq;
}
}
//---------------------------------------------------------------------------
int MyMrqmin(double *x, double *y, double *sig, int ndata, double *a, int *ia,
        int ma, double **covar, double **alpha, double *pdChiq, double *pdAlamdaq ){
double dChi, dAlamda=-1;
int i,j;

  MyMrqmin_1(x, y, sig, ndata, a, ia, ma, covar, alpha, &dChi, &dAlamda);
  *pdChiq = dChi; *pdAlamdaq = dAlamda; i=j=0;  
  
  while(dAlamda < MY_MAX_LAMDA && i<MY_MAX_TIMES_A && j<MY_MAX_TIMES_B){
     //printf("%d dAlamda=%lg\t dChi=%lg \n", i, dAlamda, dChi);
     MyMrqmin_1(x, y, sig, ndata, a, ia, ma, covar, alpha, &dChi, &dAlamda);
     if(*pdAlamdaq < dAlamda){ // On success, dAlamda will reduce 1/10 and we also monitor this
         j++;
     }else{
         j=0;
     }
     *pdAlamdaq = dAlamda;
     i++;
 }
// printf("%d dAlamda=%lg\t dChi=%lg \n", i, dAlamda, dChi);
 *pdChiq = dChi; *pdAlamdaq = dAlamda; dAlamda = 0;
 MyMrqmin_1(x, y, sig, ndata, a, ia, ma, covar, alpha, &dChi, &dAlamda);
 return i;
}
//---------------------------------------------------------------------------
#endif
