# pgf of negative binomial required

#set it up here

#call it pgf.NB


#single gamma-distributed factor where we assume we cannot define function

#obligors

n = 500

# Parameters of gamma distribution
sigma = sqrt(0.2)
alpha = sigma^{-2}
beta = sigma^{-2}

# Data
PDs = rep(0.01,n)
exposures = rep(1,n)

# Loss should be NB(alpha, beta/beta+sum(PDs))
# Compute true value at risk at 95% level

p = beta/(beta+sum(PDs))
qnbinom(0.95,size=alpha,prob=p)

# Run Monte Carlo simulation
m=10000
factors = rgamma(m,alpha,beta)
losses = rpois(m,factors*sum(PDs))
hist(losses,nclass=20)
mean(losses)
quantile(losses,0.95)

# Estimate loss distribution by FFT
max.loss = 40
N = max.loss+1
severities = rep(0,N)
severities[2] = 1
cf = pgf.NB(fft(severities),alpha,p)
invcf = Re(fft(cf,inverse=TRUE))
sum(invcf)
probs = invcf/N
loss.values = 0:max.loss

# Loss distribution
barplot(probs,names.arg=loss.values)

# c.d.f. and VaR
cdf = cumsum(probs)
plot(loss.values,cdf)
min(loss.values[cdf>=0.95])



# 2. Example with exposure bands

sigma = sqrt(0.2)
alpha = sigma^{-2}
beta = sigma^{-2}

exposures = rep(1:4,rep(250,4))
exposures
PDs = rep(c(0.01,0.005),rep(500,2))
PDs
data = data.frame(exposures,PDs)
head(data)
tail(data)

# Basic calculations
band.rates = by(PDs,exposures,sum)
band.rates
band.rates=as.vector(band.rates)
band.rates
band.exposures = unique(exposures)
band.exposures
nbands = length(band.exposures)

# Solution by Monte Carlo
m=10000
factors = rgamma(m,alpha,beta)
loss.matrix = matrix(NA,nrow=m,ncol=nbands)
for (i in 1:nbands)
    loss.matrix[,i] = band.exposures[i]*rpois(m,band.rates[i]*factors)
losses = apply(loss.matrix,1,sum)
hist(losses,nclass=20)
quantile(losses,0.95)


# Solution by FFT
multinomial.probs = band.rates/sum(band.rates)
multinomial.probs
p = beta/(beta+sum(PDs))

max.loss =80
N = max.loss+1
severities = rep(0,N)
severities[1 + (1:nbands)] = multinomial.probs
severities
plot(fft(severities))
cf = pgf.NB(fft(severities),alpha,p)
invcf = Re(fft(cf,inverse=TRUE))
sum(invcf)
probs = invcf/N
loss.values = 0:max.loss

barplot(probs,names.arg=loss.values)

cdf = cumsum(probs)
plot(loss.values,cdf)
min(loss.values[cdf>=0.95])

# Check on mean
sum(loss.values*probs)
sum(exposures*PDs)


# 3. An example with two factors and exposure bands

# set factor variances
sigma = c(sqrt(0.2),sqrt(0.1))
alpha = sigma^{-2}
beta = sigma^{-2}

exposures = rep(1:4,rep(250,4))
exposures
PDs = rep(c(0.01,0.005),rep(500,2))
PDs

w1 = c(0.8,0.2)
w2 = c(0.4,0.6)

factor1.weights = rep(c(w1[1],w2[1]),rep(500,2))
factor2.weights = rep(c(w1[2],w2[2]),rep(500,2))
data=data.frame(exposures,PDs,factor1.weights,factor2.weights)
data[1:10,]
data[990:1000,]

# completes data specification

# Solution by FFT

band.exposures = unique(exposures)
band.exposures
nbands = length(band.exposures)
p = rep(NA,2)

# Multinomial probabilities for factor 1

band.rates1 = by(PDs*factor1.weights,exposures,sum)
band.rates1
band.rates1=as.vector(band.rates1)
multinomial.probs1 = band.rates1/sum(band.rates1)
multinomial.probs1
p[1] = beta[1]/(beta[1]+sum(band.rates1))

# Multinomial probabilities for factor 2

band.rates2 = by(PDs*factor2.weights,exposures,sum)
band.rates2
band.rates2=as.vector(band.rates2)
multinomial.probs2 = band.rates2/sum(band.rates2)
multinomial.probs2
p[2] = beta[2]/(beta[2]+sum(band.rates2))

max.loss =100
N = max.loss+1

severities1 = rep(0,N)
severities1[1 + (1:nbands)] = multinomial.probs1
cf1 = pgf.NB(fft(severities1),alpha[1],p[1])

severities2 = rep(0,N)
severities2[1 + (1:nbands)] = multinomial.probs2
cf2 = pgf.NB(fft(severities2),alpha[2],p[2])

invcf = Re(fft(cf1*cf2,inverse=TRUE))
sum(invcf)
probs = invcf/N
loss.values = 0:max.loss

barplot(probs,names.arg=loss.values)

cdf = cumsum(probs)
plot(loss.values,cdf)
min(loss.values[cdf>=0.95])

# Check on mean
sum(loss.values*probs)
sum(exposures*PDs)



# Check by Monte Carlo

m=10000
band.rates = by(PDs,exposures,sum)
band.rates
band.rates=as.vector(band.rates)
band.exposures = unique(exposures)
band.exposures
nbands = length(band.exposures)
factors1 = rgamma(m,alpha[1],beta[1])
factors2 = rgamma(m,alpha[2],beta[2])

# easy simulation is a consequence of simple set-up
# each exposure band has unique factor weights
band.factors = matrix(NA,nrow=m,ncol=nbands)
band.factors[,1] = w1[1]*factors1 + w1[2]*factors2
band.factors[,2] = w1[1]*factors1 + w1[2]*factors2
band.factors[,3] = w2[1]*factors1 + w2[1]*factors2
band.factors[,4] = w2[1]*factors1 + w2[2]*factors2


loss.matrix = matrix(NA,nrow=m,ncol=nbands)
for (i in 1:nbands)
    loss.matrix[,i] = band.exposures[i]*rpois(m,band.rates[i]*band.factors[,i])
losses = apply(loss.matrix,1,sum)
hist(losses,nclass=20)
quantile(losses,0.95)


