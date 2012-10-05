@echo off
echo sets up CouchDB database, and links it to ElasticSearch
curl -XPUT http://localhost:5984/foood
curl -XPUT http://localhost:9200/_river/foood/_meta -d@river.json