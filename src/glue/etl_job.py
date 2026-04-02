import sys
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql.functions import explode, col, concat_ws

args = getResolvedOptions(sys.argv, ["JOB_NAME", "INPUT_PATH", "OUTPUT_PATH"])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Read nested JSON
df = spark.read.option("multiline", "true").json(args["INPUT_PATH"])

# Flatten: explode klines array and promote parent fields
flat_df = (
    df.select(
        col("symbol"),
        col("interval"),
        col("source"),
        col("fetched_at"),
        explode(col("klines")).alias("k"),
    )
    .select(
        col("symbol"),
        col("interval"),
        col("source"),
        col("fetched_at"),
        col("k.open_time"),
        col("k.open"),
        col("k.high"),
        col("k.low"),
        col("k.close"),
        col("k.volume"),
        col("k.close_time"),
        col("k.quote_volume"),
        col("k.trades"),
    )
)

# Hudi configuration
hudi_options = {
    "hoodie.table.name": "crypto_klines",
    "hoodie.datasource.write.recordkey.field": "symbol,open_time",
    "hoodie.datasource.write.precombine.field": "fetched_at",
    "hoodie.datasource.write.partitionpath.field": "symbol",
    "hoodie.datasource.write.operation": "upsert",
    "hoodie.datasource.write.table.type": "COPY_ON_WRITE",
    "hoodie.datasource.write.hive_style_partitioning": "true",
}

# Write to Hudi table
flat_df.write.format("hudi").options(**hudi_options).mode("append").save(
    args["OUTPUT_PATH"]
)

job.commit()
