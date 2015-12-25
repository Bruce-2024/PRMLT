function [model, llh] = rvmRegEbFp(X, t, alpha, beta)
% Relevance Vector Machine (ARD sparse prior) for regression
% training by empirical bayesian (type II ML) using fix point update (Mackay update)
% Written by Mo Chen (sth4nth@gmail.com).
if nargin < 3
    alpha = 0.02;
    beta = 0.5;
end
[d,n] = size(X);
alpha = alpha*ones(d,1);

xbar = mean(X,2);
tbar = mean(t,2);

X = bsxfun(@minus,X,xbar);
t = bsxfun(@minus,t,tbar);

XX = X*X';
Xt = X*t';

tol = 1e-4;
maxiter = 100;
llh = -inf(1,maxiter);

infinity = 1e+10;
for iter = 2 : maxiter
    used = alpha < infinity;
    d = sum(used);
    alphaUsed = alpha(used);
    S = beta*XX(used,used);
    idx = (1:d)';
    dg = sub2ind([d,d],idx,idx);
    S(dg) = S(dg)+alphaUsed;
    U = chol(S);   
    V = U\eye(d);    
    w = beta*(V*(V'*Xt(used)));               % 7.82    
    w2 = w.^2;
    err = sum((t-w'*X(used,:)).^2);
    
    logdetS = -2*sum(log(diag(V)));    
    llh(iter) = 0.5*(sum(log(alphaUsed))+n*log(beta)-beta*err-logdetS-dot(alphaUsed,w2)-n*log(2*pi)); % 3.86
    if abs(llh(iter)-llh(iter-1)) < tol*llh(iter-1); break; end

    dgSigma = dot(V,V,2);
    gamma = 1-alphaUsed.*dgSigma;   % 7.89
    alpha(used) = gamma./w2;           % 7.87
    beta = (n-sum(gamma))/err;    % 7.88
end
llh = llh(2:iter);

w0 = tbar-dot(w,xbar(used));

model.used = used;
model.w0 = w0;
model.w = w;
model.alpha = alpha;
model.beta = beta;
