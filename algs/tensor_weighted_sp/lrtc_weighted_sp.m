function [X, Out] = lrtc_weighted_sp(B, Omega, opts)

tol = 1e-8; 
max_iter = 500;
rho = 1.1;
mu = 1e-4;
max_mu = 1e10;
DEBUG = 0;

if ~exist('opts', 'var')
    opts = [];
end    
if isfield(opts, 'tol');         tol = opts.tol;              end
if isfield(opts, 'max_iter');    max_iter = opts.max_iter;    end
if isfield(opts, 'rho');         rho = opts.rho;              end
if isfield(opts, 'mu');          mu = opts.mu;                end
if isfield(opts, 'max_mu');      max_mu = opts.max_mu;        end
if isfield(opts, 'DEBUG');       DEBUG = opts.DEBUG;          end
if isfield(opts, 'sp');          sp = opts.sp;                end

sp_opts = [];
sp_opts.iter_begin_flag = 1;
sp_opts.sp = sp;
sp_opts.type = 0;

sz = size(B);
X = B; 
Y = zeros(sz); %% 
M = zeros(sz); %%

Out.Res=[];Out.ResT=[]; Out.PSNR=[];
for k = 1:max_iter
    %% solve Y-subproblem
    Yold = Y;
    [Y,~] = prox_sp_norm_weighted(X + M/mu, 1/mu, sp_opts);
    %% solve X-subproblem
    Xold = X;
    X = Y - M / mu;
    X(Omega) = B(Omega);
    %% check the convergence
    if isfield(opts, 'Xtrue')
        XT=opts.Xtrue;    
        resT=norm(X(:)-XT(:))/norm(XT(:)); 
        psnrT=psnr(X,XT);
        Out.ResT = [Out.ResT,resT];
        Out.PSNR = [Out.PSNR,psnrT];
    end 
    res=norm(X(:)-Xold(:))/norm(Xold(:));
    Out.Res = [Out.Res,res];  
    if DEBUG
        if k==1 || mod(k, 10) == 0
            if isfield(opts, 'Xtrue')
                fprintf('Iter = %d   PSNR=%f   res=%f   real-res=%f\n', k, psnrT, res, resT);
            else
                fprintf('Iter = %d   res=%f   \n', k, res);
            end
        end
    end
    chgX = max(abs(X(:)-Xold(:)));
    chgY = max(abs(Y(:)-Yold(:)));
    chaXY = max(abs(X(:)-Y(:)));
    chg = max([ chgX chgY chaXY ]);
    if chg < tol 
        break;
    end
    
    %% update Lagrange multiplier
    M = M + mu * (X - Y);
    mu = min(rho * mu, max_mu);
end

end 

