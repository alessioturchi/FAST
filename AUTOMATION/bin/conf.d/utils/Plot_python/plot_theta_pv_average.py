#!/usr/bin/python3
from __future__ import print_function

import sys,traceback
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import Polygon
import numpy as np

class Header(object):
    def __init__(self, dfile, utoffset) :
        self.dfile=dfile
        self.utoffset=utoffset
        filefd = open(dfile)
        filefd.readline()
        self.linefile=filefd.readline()
        hfields = self.linefile.split()
        if len(hfields) != 8:
            print("!!!ERROR: wrong header")
            sys.exit(2)
        filefd.close()
        self.deltat=float(hfields[0])/60.
        self.starttime=float(hfields[1])/60.
        self.endtime=float(hfields[2])/60.
        self.heightlow=float(hfields[3])/1000-0.5
        self.heighthigh=float(hfields[4])/1000+0.5

        self.starthour=int(self.starttime)
        self.startminute=int((self.starttime-self.starthour)*60.)
        self.endhour=int(self.endtime)
        self.endminute=int((self.endtime-self.endhour)*60.)
    
        self.starthourlt=int(self.starthour+utoffset)
        if self.starthourlt < 0 :
            self.starthourlt += 24
        if self.starthourlt > 24 :
            self.starthourlt -= 24
        self.endhourlt=int(self.endhour+utoffset)
        if self.endhourlt < 0 :
            self.endhourlt += 24
        if self.endhourlt > 24 :
            self.endhourlt -= 24

        self.stringaora=str(self.starthour).strip()+":"
        if (self.startminute <= 9):
            self.stringaora=self.stringaora+'0'+str(self.startminute).strip()
        if (self.startminute >= 10):
            self.stringaora=self.stringaora+str(self.startminute).strip()
        self.stringaora=self.stringaora+'-'+str(self.endhour).strip()+":"
        if (self.endminute <= 9):
            self.stringaora=self.stringaora+'0'+str(self.endminute).strip()
        if (self.endminute >= 10):
            self.stringaora=self.stringaora+str(self.endminute).strip()

        self.stringaoralt=str(self.starthourlt).strip()+":"
        if (self.startminute <= 9):
            self.stringaoralt=self.stringaoralt+'0'+str(self.startminute).strip()
        if (self.startminute >= 10):
            self.stringaoralt=self.stringaoralt+str(self.startminute).strip()
        self.stringaoralt=self.stringaoralt+'-'+str(self.endhourlt).strip()+":"
        if (self.endminute <= 9):
            self.stringaoralt=self.stringaoralt+'0'+str(self.endminute).strip()
        if (self.endminute >= 10):
            self.stringaoralt=self.stringaoralt+str(self.endminute).strip()

    def __str__(self):
        return '%s: %f %f %f %f %f %f %f \n %s'%(self.dfile, self.utoffset,self.deltat, self.starttime, self.endtime, self.endtime, self.heightlow, self.heighthigh, self.linefile, self.stringaora, self.stringaoralt)

class Datastore(object):
    def __init__(self,files) :
        data=np.loadtxt(files[0],skiprows=3)
        self.rows,self.cols=data.shape
        nfiles=len(files)
        data_all=np.zeros((self.rows,self.cols,nfiles),float)
        for i,dfile in enumerate(files):
            data_all[:,:,i]=np.loadtxt(dfile,skiprows=3)
        self.heights=data_all[:,0,0]/1000.
        self.theta=data_all[:,1,:]
        self.theta_sd=data_all[:,2,:]
        self.thetalow=self.theta-self.theta_sd
        self.thetaup=self.theta+self.theta_sd

def main():
    files=sys.argv[1:4]
    nfiles=len(files)    
    data=Datastore(files)
    utoffset=int(sys.argv[4])
    YEARF=str(sys.argv[5])
    MONTHF=str(sys.argv[6])
    DAYF=str(sys.argv[7])
    stringadata_fig=str(YEARF).strip()+'/'+str(MONTHF).strip()+'/'+str(DAYF).strip()

    hd=Header(files[0],utoffset)
    #Set limits
    maxval=np.max(data.theta+data.theta_sd)
    minval=np.min(data.theta-data.theta_sd)

    stringheora_ut=[]
    stringheora_lt=[]
    for i in range(nfiles):
        #Base settings
        my_dpi=300
        font_size=9

        #Load header
        hd=Header(files[i],utoffset)
        stringheora_ut.append(hd.stringaora)
        stringheora_lt.append(hd.stringaoralt)

        #Plot theta
        title_label='Potential Temperature - Averaged in ['+hd.stringaora+']h UT or ['+hd.stringaoralt+']h MST'
        xpoly=np.concatenate((data.thetaup[:,i],data.thetalow[::-1,i]))
        ypoly=np.concatenate((data.heights,data.heights[::-1]))
        plt.figure(figsize=(1676./my_dpi, 1003./my_dpi), dpi=my_dpi)
        plt.rcParams.update({'mathtext.default':  'regular' })
        plt.rcParams['axes.labelsize'] = font_size
        plt.rcParams['xtick.labelsize'] = font_size
        plt.rcParams['ytick.labelsize'] = font_size
        plt.plot(data.theta[:,i],data.heights,color='k',linewidth=1)
        plt.plot(data.thetalow[:,i],data.heights,':',color='k',linewidth=0.5)
        plt.plot(data.thetaup[:,i],data.heights,':',color='k',linewidth=0.5)
#        plt.xscale('log')
        plt.fill(xpoly,ypoly,color='#87CEEB')
#        plt.axes().set_aspect(0.36)
        plt.tick_params(which='both')
        plt.tick_params(which='major', length=7)
        plt.tick_params(which='minor', length=4)
        plt.minorticks_on()
        plt.title(title_label,fontsize=font_size)
        plt.xlabel('Potential Temperature (K))')
        plt.ylabel('Height (km) a.g.l.')
        ax = plt.gca()
        plt.text(0, -0.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
        plt.xlim(minval,maxval)
        plt.ylim(hd.heightlow,hd.heighthigh)
        plt.tight_layout()
#        plt.subplots_adjust(left=0.09, right=0.95, top=0.93, bottom=0.15)
        
        fileout="DATE_theta_pv_avg_0"+str(i+1)+".png"
        plt.savefig(fileout,dpi=my_dpi)
        print("Creato file con plot:", fileout)

        #Write out dat file
        fname="DATE_theta_pv_avg_0"+str(i+1)+".dat"
        f = open(fname, 'w')
        f.write('### POTENTIAL TEMPERATURE VERTICAL PROFILE TIME AVERAGED IN '+hd.stringaora+' UT '+'\n')
        f.write('### HEIGHT(m) THETA_AVG(K) SIGMA_THETA(K)'+'\n')
        printdata=np.zeros((1,3),float)
        for j in range(data.rows):
            printdata[0,0]=data.heights[j]
            printdata[0,1]=data.theta[j,i]
            printdata[0,2]=data.theta_sd[j,i]
            np.savetxt(f,printdata,fmt='%E',delimiter='\t')
        f.close()

#FINAL PLOT WITH SUPERIMPOSED FIGURES
    #Plot theta speed
    title_label='Potential Temperature - Averaged vertical profiles'
    plt.figure(figsize=(1676./my_dpi, 1303./my_dpi), dpi=my_dpi)
    plt.rcParams['axes.labelsize'] = font_size
    plt.rcParams['xtick.labelsize'] = font_size
    plt.rcParams['ytick.labelsize'] = font_size
    plt.plot(data.theta[:,0],data.heights,color='r',linewidth=1,label=stringheora_ut[0]+' UT - '+stringheora_ut[0]+' MST')
    plt.plot(data.theta[:,1],data.heights,color='b',linewidth=1,label=stringheora_ut[1]+' UT - '+stringheora_ut[1]+' MST')
    plt.plot(data.theta[:,2],data.heights,color='g',linewidth=1,label=stringheora_ut[2]+' UT - '+stringheora_ut[2]+' MST')
    plt.legend(loc='lower left',bbox_to_anchor=(0., 1.1), shadow=True, fontsize=font_size)
#        plt.axes().set_aspect(0.36)
    plt.tick_params(which='both')
    plt.tick_params(which='major', length=7)
    plt.tick_params(which='minor', length=4)
    plt.minorticks_on()
    plt.title(title_label,fontsize=font_size)
    plt.xlabel('Potential Temperature (K))')    
    plt.ylabel('Height (km) a.g.l.')
    ax = plt.gca()
    plt.text(0, -0.13,stringadata_fig,verticalalignment='center',transform = ax.transAxes, fontsize=font_size+1)
    plt.xlim(minval,maxval)
    plt.ylim(hd.heightlow,hd.heighthigh)
    plt.tight_layout()
    plt.subplots_adjust(left=0.09, right=0.95, top=0.77, bottom=0.12)
    fileout="DATE_theta_pv_avg_ALL.png"
    plt.savefig(fileout,dpi=my_dpi)
    print("Creato file con plot:", fileout)

if __name__ == '__main__':
    try:
        main()
    except:
        print("!!!Error: error plotting plot_theta_pv_avg.py with input parameters: ",sys.argv)
        print(traceback.format_exc())
        sys.exit(1)


