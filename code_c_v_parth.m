clear;
close all;
clc;

%% Input parameters
phi_m =4.05 ;      %work function of metal
dV_g = 0.005;
V_g=-2.5:dV_g:2.5;            %gate voltage
t_ox=10e-9;          %oxide thickness 
N_sub=-1e17*1e6;      %-ve=p type substrate(NMOS), +ve=n type substrate(PMOS), input doping density here
V_wiggle=10e-3;

%% Constants
q=1.6e-19;
k=8.314/(6.023*10^23);
T=300;
eps_0=8.85e-12; 
Vt=k*T/q;          %thermal voltage

%% Substrate parameters

ni=1.5e16;          % number of instrinsic carriers in silicon substrate
Eg_sub=1.12*q;      %band gap of silicon, 1.12eV
eps_sub=12*eps_0;   %permitivitty of silicon substrate
EA_sub=4.05*q;      %electron affinity for substrate
L_sub=1e-6;
k_sub=12;

%calculating the value of n and p for substrate
if(N_sub<0)                %p type substrate(NMOS)
    p_sub=abs(N_sub);
    n_sub=ni^2/p_sub;
elseif(N_sub>0)            %n type substrate(PMOS)
    n_sub=N_sub;
    p_sub=ni^2/n_sub;
else                       %intrinsic semiconductor
    n_sub=ni;
    p_sub=pi;
end   

%% Oxide parameters

eps_ox=4*eps_0;    %permitivitty of SiO2
Ec_offset=3.1*q;   %conduction band offset
Eg_ox=9*q;         %band gap of oxide
c_ox=eps_ox/t_ox;
k_ox=4;

%% Workfunction,flatband values;

phi_b = -sign(N_sub)*Vt*log(abs(N_sub)/ni);   %Ei-Ef/q for semiconductor
phi_s = EA_sub/q+Eg_sub/(2*q)+phi_b;          %work function for substrate
V_fb=(phi_m-phi_s) ;                          %flatband voltage
tm = 10e-9;                                   %Gate thickness, used for polysilicon, not of use in metalgate

%% Solver parameters
dx=1e-9;
I_max=50;
tol1=1e-6;

% Sign of substrate charges in the current mode, since we have signum(psi_s) in formula of charge

if(V_g>=V_fb)
    signq = -1;       %Depletion for NMOS, Accumulation for PMOS
else                  % i.e. (V_g<V_fb)
    signq = +1;       %Accumulation for NMOS, Depletion for PMOS
end

%Same charge sign for depletion and inversion

% if sign(N_sub) <= 0
%     F = @(sp) V_fb-(signq*((2*eps_sub*k*T*abs(N_sub))^0.5*((exp(-q*sp/(k*T))+q*sp/(k*T)-1)+(ni^2/(abs(N_sub))^2)*(exp(+q*sp/(k*T))-q*sp/(k*T)-1))^0.5)/c_ox)+sp-V_g;
%     psi_s = fsolve(F,-signq*0.1); % Initial guess, sign taken due to fsolve
%     
% else                              % sign(N_sub) > 0
%     F = @(sp) V_fb-(signq*((2*eps_sub*k*T*abs(N_sub))^0.5*((ni^2/(abs(N_sub))^2)*(exp(-q*sp/(k*T))+q*sp/(k*T)-1)+(exp(+q*sp/(k*T))-q*sp/(k*T)-1))^0.5)/c_ox)+sp-V_g;
%     psi_s = fsolve(F,-signq*0.1); % Initial guess, sign taken due to fsolve
% end


%%  LFCV
C=zeros(length(V_g),1);
Q1=zeros(length(V_g),1);
Q2=zeros(length(V_g),1);
for i=1:length(V_g)
    
    if (abs(V_g - V_fb) < 5*dV_g)
        V_g(i) = [];
        C(i) = [];
        break;
    else        
        if(V_g(i)>V_fb + 0*dV_g)
        signq = -1;                                  %Depletion for NMOS, Accumulation for PMOS
        else (V_g(i)<V_fb - 0*dV_g)                  % i.e. (V_g<V_fb)
        signq = +1;                                  %Accumulation for NMOS, Depletion for PMOS
        end
    end

    
    if(V_g(i)+V_wiggle>=V_fb)
    signq2 = -1;       %Depletion for NMOS, Accumulation for PMOS
    else                  % i.e. (V_g<V_fb)
    signq2 = +1;       %Accumulation for NMOS, Depletion for PMOS
    end
    
 F1 = @(sp) V_fb-(signq*((2*eps_sub*k*T*abs(N_sub))^0.5*((exp(-q*sp/(k*T))+q*sp/(k*T)-1)+(ni^2/(abs(N_sub))^2)*(exp(+q*sp/(k*T))-q*sp/(k*T)-1))^0.5)/c_ox)+sp-V_g(i);
 psi_s = fsolve(F1,-signq*0.1); % Initial guess, sign taken due to fsolve
 
 Q1(i,1)=signq*((2*eps_sub*k*T*abs(N_sub))^0.5*((exp(-q*psi_s/(k*T))+q*psi_s/(k*T)-1)+(ni^2/(abs(N_sub))^2)*(exp(+q*psi_s/(k*T))-q*psi_s/(k*T)-1))^0.5);

 F2 = @(sp) V_fb-(signq2*((2*eps_sub*k*T*abs(N_sub))^0.5*((exp(-q*sp/(k*T))+q*sp/(k*T)-1)+(ni^2/(abs(N_sub))^2)*(exp(+q*sp/(k*T))-q*sp/(k*T)-1))^0.5)/c_ox)+sp-V_g(i)-V_wiggle;
  
 psi_s = fsolve(F2,-signq*0.1); % Initial guess, sign taken due to fsolve
 Q2(i,1)=signq*((2*eps_sub*k*T*abs(N_sub))^0.5*((exp(-q*psi_s/(k*T))+q*psi_s/(k*T)-1)+(ni^2/(abs(N_sub))^2)*(exp(+q*psi_s/(k*T))-q*psi_s/(k*T)-1))^0.5);
  
 C(i,1)=abs((Q2(i,1))-(Q1(i,1)))/V_wiggle;
  
  
  
end
axes();
plot(V_g,C,'LineWidth',1.5);
hold on;
%plot([0 10], [0 0], 'k-')
xlabel('Voltage(in V)');
ylabel('Capacitance(in F/cm^2)');
grid on;
ax=gca;
ax.FontSize=10;
