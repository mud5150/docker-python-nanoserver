FROM microsoft/windowsservercore:1809 as base

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV PYTHON_VERSION 3.6.5
ENV PYTHON_RELEASE 3.6.5

RUN $url = ('https://www.python.org/ftp/python/{0}/python-{1}-amd64.exe' -f $env:PYTHON_RELEASE, $env:PYTHON_VERSION); \
	Write-Host ('Downloading {0} ...' -f $url); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri $url -OutFile 'python.exe'; \
	\
	Write-Host 'Installing ...'; \
# https://docs.python.org/3.5/using/windows.html#installing-without-ui
	Start-Process python.exe -Wait \
		-ArgumentList @( \
			'/quiet', \
			'InstallAllUsers=1', \
			'TargetDir=C:\Python', \
			'PrependPath=1', \
			'Shortcuts=0', \
			'Include_doc=0', \
			'Include_pip=0', \
			'Include_test=0' \
		); \
	\
# the installer updated PATH, so we should refresh our local value
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Verifying install ...'; \
	Write-Host '  python --version'; python --version; \
	\
	Write-Host 'Removing ...'; \
	Remove-Item python.exe -Force; \
	\
	Write-Host 'Complete.';

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 9.0.3

RUN Write-Host ('Installing pip=={0} ...' -f $env:PYTHON_PIP_VERSION); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py'; \
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		('pip=={0}' -f $env:PYTHON_PIP_VERSION) \
	; \
	Remove-Item get-pip.py -Force; \
	\
	Write-Host 'Verifying pip install ...'; \
	pip --version; \
	\
	Write-Host 'Complete.';

FROM microsoft/nanoserver:1809

COPY --from=base ["Python", "Python"]

USER ContainerAdministrator
RUN setx /M PATH %PATH%;c:\Python\;c:\Python\scripts\;
USER ContainerUser

CMD ["python"]
