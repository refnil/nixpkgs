{ lib, fetchPypi, buildPythonPackage
, six, sqlalchemy
, mock, pytz, isort, flake8, jinja2, pg8000, pyodbc, pytest, pymysql, dateutil
, docutils, flexmock, psycopg2, pygments }:

buildPythonPackage rec {
  pname = "sqlalchemy-utils";
  version = "0.36.6";

  src = fetchPypi {
    inherit version;
    pname = "SQLAlchemy-Utils";
    sha256 = "0srs5w486wp5zydjs70igi5ypgxhm6h73grb85jz03fqpqaanzvs";
  };

  propagatedBuildInputs = [
    six
    sqlalchemy
  ];

  # Attempts to access localhost and there's also no database access
  doCheck = false;
  checkInputs = [
    mock
    pytz
    isort
    flake8
    jinja2
    pg8000
    pyodbc
    pytest
    pymysql
    dateutil
    docutils
    flexmock
    psycopg2
    pygments
  ];

  checkPhase = ''
    pytest tests
  '';

  meta = with lib; {
    homepage = "https://github.com/kvesteri/sqlalchemy-utils";
    description = "Various utility functions and datatypes for SQLAlchemy";
    license = licenses.bsd3;
    maintainers = with maintainers; [ eadwu ];
  };
}
