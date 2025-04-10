"""
Amazon Data Analyst Prep - Python Module
Days 8-11: Data Cleaning, Transformation, EDA, and Statistical Analysis
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats
from datetime import datetime, timedelta
import warnings
warnings.filterwarnings('ignore')

# ============================================
# DAY 8: DATA CLEANING BASICS
# ============================================

# EXERCISE 1: Load and inspect data
def load_and_inspect_data():
    """Load CSV file and perform initial data quality checks"""
    df = pd.read_csv('data/customer_orders.csv')
    
    print("Dataset Shape:", df.shape)
    print("\nFirst 5 rows:\n", df.head())
    print("\nData Types:\n", df.dtypes)
    print("\nMissing Values:\n", df.isnull().sum())
    print("\nBasic Statistics:\n", df.describe())
    
    return df


# EXERCISE 2: Handle missing values
def handle_missing_values(df):
    """Demonstrate different strategies for handling missing data"""
    
    # Check missing values
    print("Missing values before:")
    print(df.isnull().sum())
    
    # Strategy 1: Drop rows with any missing values
    df_dropped = df.dropna()
    
    # Strategy 2: Drop rows where specific column is missing
    df_specific = df.dropna(subset=['customer_id'])
    
    # Strategy 3: Fill missing values with mean (numerical columns)
    df_filled_mean = df.copy()
    df_filled_mean['order_amount'] = df_filled_mean['order_amount'].fillna(df_filled_mean['order_amount'].mean())
    
    # Strategy 4: Fill missing values with forward fill (time series)
    df_filled_ffill = df.sort_values('order_date').copy()
    df_filled_ffill['product_category'] = df_filled_ffill['product_category'].fillna(method='ffill')
    
    # Strategy 5: Fill missing values with specific value
    df_filled_value = df.copy()
    df_filled_value['country'] = df_filled_value['country'].fillna('Unknown')
    
    print("\nMissing values after handling:")
    print(df_filled_mean.isnull().sum())
    
    return df_filled_mean


# EXERCISE 3: Remove duplicates
def remove_duplicates(df):
    """Handle duplicate records in dataset"""
    
    print(f"Original rows: {len(df)}")
    
    # Find duplicates
    duplicate_mask = df.duplicated()
    print(f"Duplicate rows: {duplicate_mask.sum()}")
    
    # Find duplicates based on specific columns
    duplicate_customer_orders = df.duplicated(subset=['customer_id', 'order_id'])
    print(f"Duplicate customer-order combinations: {duplicate_customer_orders.sum()}")
    
    # Remove all duplicates (keeps first occurrence)
    df_unique = df.drop_duplicates()
    
    # Remove duplicates keeping last occurrence
    df_unique_last = df.drop_duplicates(keep='last')
    
    print(f"Rows after removing duplicates: {len(df_unique)}")
    
    return df_unique


# EXERCISE 4: Data type conversion
def convert_data_types(df):
    """Convert columns to appropriate data types"""
    
    # Convert to appropriate types
    df['customer_id'] = df['customer_id'].astype('int64')
    df['order_amount'] = pd.to_numeric(df['order_amount'], errors='coerce')
    df['order_date'] = pd.to_datetime(df['order_date'], format='%Y-%m-%d')
    
    # Create categorical columns for efficiency
    df['product_category'] = df['product_category'].astype('category')
    df['country'] = df['country'].astype('category')
    
    print("Data types after conversion:")
    print(df.dtypes)
    
    # Check memory usage
    print(f"\nMemory usage: {df.memory_usage(deep=True).sum() / 1024**2:.2f} MB")
    
    return df


# EXERCISE 5: Data validation and quality checks
def validate_data_quality(df):
    """Validate data quality with business rules"""
    
    issues = []
    
    # Check for negative amounts
    negative_amounts = df[df['order_amount'] < 0]
    if len(negative_amounts) > 0:
        issues.append(f"Found {len(negative_amounts)} negative order amounts")
    
    # Check for future dates
    future_dates = df[df['order_date'] > pd.Timestamp.now()]
    if len(future_dates) > 0:
        issues.append(f"Found {len(future_dates)} future order dates")
    
    # Check for invalid email format
    invalid_emails = df[~df['email'].str.contains(r'^[\w\.-]+@[\w\.-]+\.\w+$', regex=True, na=False)]
    if len(invalid_emails) > 0:
        issues.append(f"Found {len(invalid_emails)} invalid email addresses")
    
    # Check for whitespace issues
    whitespace_names = df[df['customer_name'].str.strip() != df['customer_name']]
    if len(whitespace_names) > 0:
        issues.append(f"Found {len(whitespace_names)} names with leading/trailing whitespace")
    
    if issues:
        print("Data Quality Issues Found:")
        for issue in issues:
            print(f"  - {issue}")
    else:
        print("No data quality issues found!")
    
    return issues


# ============================================
# DAY 9: DATA TRANSFORMATION
# ============================================

# EXERCISE 1: Merge DataFrames
def merge_customer_orders(customers_df, orders_df):
    """Merge customer and order data"""
    
    # INNER JOIN (only matching records)
    df_inner = pd.merge(customers_df, orders_df, on='customer_id', how='inner')
    
    # LEFT JOIN (all customers, matching orders)
    df_left = pd.merge(customers_df, orders_df, on='customer_id', how='left')
    
    # OUTER JOIN (all records from both tables)
    df_outer = pd.merge(customers_df, orders_df, on='customer_id', how='outer')
    
    print(f"Inner join: {len(df_inner)} rows")
    print(f"Left join: {len(df_left)} rows")
    print(f"Outer join: {len(df_outer)} rows")
    
    return df_inner


# EXERCISE 2: Reshape data (Pivot)
def pivot_sales_by_month(df):
    """Convert sales data from long to wide format"""
    
    # Create pivot table
    pivot_df = df.pivot_table(
        values='order_amount',
        index='product_category',
        columns=pd.Grouper(key='order_date', freq='M'),
        aggfunc='sum',
        fill_value=0
    )
    
    print("Pivot Table (Sales by Product Category by Month):")
    print(pivot_df)
    
    return pivot_df


# EXERCISE 3: Unpivot data (Melt)
def unpivot_monthly_sales(df):
    """Convert sales data from wide to long format"""
    
    # Assuming df has columns: product_id, Jan, Feb, Mar, Apr
    melted_df = df.melt(
        id_vars=['product_id'],
        value_vars=['Jan', 'Feb', 'Mar', 'Apr'],
        var_name='month',
        value_name='sales'
    )
    
    print("Melted Data:")
    print(melted_df.head())
    
    return melted_df


# EXERCISE 4: String operations
def clean_string_data(df):
    """Clean and standardize string columns"""
    
    df_clean = df.copy()
    
    # Convert to lowercase
    df_clean['product_name'] = df_clean['product_name'].str.lower()
    
    # Remove whitespace
    df_clean['customer_name'] = df_clean['customer_name'].str.strip()
    
    # Extract text patterns
    df_clean['area_code'] = df_clean['phone'].str.extract(r'(\d{3})')
    
    # Replace text
    df_clean['country'] = df_clean['country'].str.replace('USA', 'United States')
    
    # Check if string contains pattern
    df_clean['is_premium'] = df_clean['product_name'].str.contains('premium', case=False)
    
    return df_clean


# EXERCISE 5: Date and time operations
def transform_date_features(df):
    """Create useful date features from timestamp"""
    
    df_time = df.copy()
    df_time['order_date'] = pd.to_datetime(df_time['order_date'])
    
    # Extract date components
    df_time['year'] = df_time['order_date'].dt.year
    df_time['month'] = df_time['order_date'].dt.month
    df_time['day'] = df_time['order_date'].dt.day
    df_time['quarter'] = df_time['order_date'].dt.quarter
    df_time['week'] = df_time['order_date'].dt.isocalendar().week
    df_time['day_of_week'] = df_time['order_date'].dt.day_name()
    
    # Calculate days since event
    df_time['days_since_order'] = (pd.Timestamp.now() - df_time['order_date']).dt.days
    
    # Check if weekend
    df_time['is_weekend'] = df_time['order_date'].dt.dayofweek.isin([5, 6])
    
    return df_time


# EXERCISE 6: Apply custom functions
def create_derived_features(df):
    """Create new features using custom functions"""
    
    df_features = df.copy()
    
    # Custom function for order size classification
    def classify_order_size(amount):
        if amount < 100:
            return 'Small'
        elif amount < 500:
            return 'Medium'
        elif amount < 1000:
            return 'Large'
        else:
            return 'Very Large'
    
    df_features['order_size'] = df_features['order_amount'].apply(classify_order_size)
    
    # Lambda function for quick transformations
    df_features['order_amount_rounded'] = df_features['order_amount'].apply(lambda x: round(x, 2))
    
    # Apply to multiple columns
    df_features[['first_name', 'last_name']] = df_features['customer_name'].str.split(' ', n=1, expand=True)
    
    return df_features


# ============================================
# DAY 10: EXPLORATORY DATA ANALYSIS (EDA)
# ============================================

# EXERCISE 1: Descriptive statistics
def descriptive_statistics(df):
    """Compute comprehensive descriptive statistics"""
    
    print("=" * 60)
    print("DESCRIPTIVE STATISTICS")
    print("=" * 60)
    
    print("\nNumerical Columns Summary:")
    print(df.describe())
    
    print("\nCategorical Columns Summary:")
    print(df.select_dtypes(include=['object', 'category']).describe())
    
    # Percentile analysis
    print("\nPercentile Analysis (Order Amount):")
    for percentile in [10, 25, 50, 75, 90, 99]:
        value = df['order_amount'].quantile(percentile/100)
        print(f"  {percentile}th percentile: ${value:.2f}")
    
    # Skewness and Kurtosis
    print(f"\nSkewness: {df['order_amount'].skew():.2f}")
    print(f"Kurtosis: {df['order_amount'].kurtosis():.2f}")


# EXERCISE 2: Distribution analysis
def analyze_distributions(df):
    """Analyze distributions of key variables"""
    
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    
    # Histogram
    axes[0, 0].hist(df['order_amount'], bins=30, edgecolor='black')
    axes[0, 0].set_title('Distribution of Order Amount')
    axes[0, 0].set_xlabel('Order Amount ($)')
    axes[0, 0].set_ylabel('Frequency')
    
    # Box plot
    axes[0, 1].boxplot(df['order_amount'])
    axes[0, 1].set_title('Box Plot of Order Amount')
    axes[0, 1].set_ylabel('Order Amount ($)')
    
    # Q-Q plot (check normality)
    stats.probplot(df['order_amount'], dist="norm", plot=axes[1, 0])
    axes[1, 0].set_title('Q-Q Plot')
    
    # Violin plot by category
    df.boxplot(column='order_amount', by='product_category', ax=axes[1, 1])
    axes[1, 1].set_title('Order Amount by Product Category')
    
    plt.tight_layout()
    plt.savefig('outputs/distributions.png', dpi=300, bbox_inches='tight')
    plt.show()


# EXERCISE 3: Correlation analysis
def correlation_analysis(df):
    """Analyze relationships between variables"""
    
    # Calculate correlation matrix
    numeric_df = df.select_dtypes(include=[np.number])
    correlation_matrix = numeric_df.corr()
    
    # Visualize correlation heatmap
    plt.figure(figsize=(10, 8))
    sns.heatmap(correlation_matrix, annot=True, fmt='.2f', cmap='coolwarm', center=0)
    plt.title('Correlation Matrix Heatmap')
    plt.tight_layout()
    plt.savefig('outputs/correlation_heatmap.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    # Print strong correlations
    print("Strong Correlations (> 0.7 or < -0.7):")
    for i in range(len(correlation_matrix.columns)):
        for j in range(i+1, len(correlation_matrix.columns)):
            if abs(correlation_matrix.iloc[i, j]) > 0.7:
                col1 = correlation_matrix.columns[i]
                col2 = correlation_matrix.columns[j]
                corr_val = correlation_matrix.iloc[i, j]
                print(f"  {col1} <-> {col2}: {corr_val:.2f}")


# EXERCISE 4: Outlier detection
def detect_outliers(df):
    """Identify and handle outliers"""
    
    # Method 1: IQR (Interquartile Range)
    Q1 = df['order_amount'].quantile(0.25)
    Q3 = df['order_amount'].quantile(0.75)
    IQR = Q3 - Q1
    
    lower_bound = Q1 - 1.5 * IQR
    upper_bound = Q3 + 1.5 * IQR
    
    outliers_iqr = df[(df['order_amount'] < lower_bound) | (df['order_amount'] > upper_bound)]
    print(f"Outliers (IQR method): {len(outliers_iqr)} ({len(outliers_iqr)/len(df)*100:.1f}%)")
    
    # Method 2: Z-score
    z_scores = np.abs(stats.zscore(df['order_amount']))
    outliers_zscore = df[z_scores > 3]
    print(f"Outliers (Z-score > 3): {len(outliers_zscore)} ({len(outliers_zscore)/len(df)*100:.1f}%)")
    
    # Visualize outliers
    plt.figure(figsize=(12, 4))
    
    plt.subplot(1, 2, 1)
    plt.boxplot(df['order_amount'])
    plt.title('Box Plot - Outliers Highlighted')
    plt.ylabel('Order Amount ($)')
    
    plt.subplot(1, 2, 2)
    plt.scatter(range(len(df)), df['order_amount'].values, alpha=0.5)
    plt.axhline(upper_bound, color='r', linestyle='--', label='Upper Bound')
    plt.axhline(lower_bound, color='r', linestyle='--', label='Lower Bound')
    plt.title('Scatter Plot - Outliers Highlighted')
    plt.ylabel('Order Amount ($)')
    plt.legend()
    
    plt.tight_layout()
    plt.savefig('outputs/outliers.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return outliers_iqr, outliers_zscore


# EXERCISE 5: Categorical analysis
def analyze_categories(df):
    """Analyze categorical variables"""
    
    # Value counts
    print("Product Category Distribution:")
    print(df['product_category'].value_counts())
    
    print("\nProduct Category Proportions:")
    print(df['product_category'].value_counts(normalize=True))
    
    # Cross tabulation
    crosstab = pd.crosstab(df['product_category'], df['country'], margins=True)
    print("\nCross Tabulation (Category vs Country):")
    print(crosstab)
    
    # Visualize
    fig, axes = plt.subplots(1, 2, figsize=(12, 4))
    
    df['product_category'].value_counts().plot(kind='bar', ax=axes[0])
    axes[0].set_title('Product Category Distribution')
    axes[0].set_xlabel('Category')
    axes[0].set_ylabel('Count')
    
    df['product_category'].value_counts().plot(kind='pie', ax=axes[1], autopct='%1.1f%%')
    axes[1].set_title('Product Category Proportion')
    
    plt.tight_layout()
    plt.savefig('outputs/categorical_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()


# ============================================
# DAY 11: STATISTICAL ANALYSIS
# ============================================

# EXERCISE 1: Hypothesis testing
def hypothesis_testing_example(df):
    """Conduct hypothesis tests"""
    
    print("=" * 60)
    print("HYPOTHESIS TESTING")
    print("=" * 60)
    
    # Hypothesis 1: Average order amount = $500
    t_stat, p_value = stats.ttest_1samp(df['order_amount'], 500)
    print(f"\nH0: Average order amount = $500")
    print(f"T-statistic: {t_stat:.4f}")
    print(f"P-value: {p_value:.4f}")
    if p_value < 0.05:
        print("Result: Reject H0 (Average order amount ≠ $500)")
    else:
        print("Result: Fail to reject H0 (Average order amount = $500)")
    
    # Hypothesis 2: Order amounts differ by category
    category_groups = [group['order_amount'].values for name, group in df.groupby('product_category')]
    f_stat, p_value = stats.f_oneway(*category_groups)
    print(f"\nH0: Order amounts are equal across product categories")
    print(f"F-statistic: {f_stat:.4f}")
    print(f"P-value: {p_value:.4f}")
    if p_value < 0.05:
        print("Result: Reject H0 (Order amounts differ by category)")
    else:
        print("Result: Fail to reject H0 (Order amounts are equal)")


# EXERCISE 2: A/B Testing
def ab_testing_example(df):
    """Perform A/B test analysis"""
    
    print("\n" + "=" * 60)
    print("A/B TESTING")
    print("=" * 60)
    
    # Assume we have two groups (e.g., control vs treatment)
    control = df[df['test_group'] == 'control']['order_amount']
    treatment = df[df['test_group'] == 'treatment']['order_amount']
    
    # Independent samples t-test
    t_stat, p_value = stats.ttest_ind(control, treatment)
    
    print(f"\nControl Group:")
    print(f"  Mean: ${control.mean():.2f}")
    print(f"  Std Dev: ${control.std():.2f}")
    print(f"  N: {len(control)}")
    
    print(f"\nTreatment Group:")
    print(f"  Mean: ${treatment.mean():.2f}")
    print(f"  Std Dev: ${treatment.std():.2f}")
    print(f"  N: {len(treatment)}")
    
    print(f"\nT-Test Results:")
    print(f"  T-statistic: {t_stat:.4f}")
    print(f"  P-value: {p_value:.4f}")
    print(f"  Significance level: α = 0.05")
    
    if p_value < 0.05:
        print(f"  Result: SIGNIFICANT difference (p < 0.05)")
        print(f"  Lift: {((treatment.mean() - control.mean()) / control.mean() * 100):.1f}%")
    else:
        print(f"  Result: NO significant difference (p >= 0.05)")
    
    # Calculate confidence interval
    mean_diff = treatment.mean() - control.mean()
    se = np.sqrt(control.var()/len(control) + treatment.var()/len(treatment))
    ci_lower = mean_diff - 1.96 * se
    ci_upper = mean_diff + 1.96 * se
    
    print(f"\n95% Confidence Interval for Mean Difference:")
    print(f"  [{ci_lower:.2f}, {ci_upper:.2f}]")


# EXERCISE 3: Cohort analysis
def cohort_analysis(df):
    """Analyze customer cohorts and retention"""
    
    print("\n" + "=" * 60)
    print("COHORT ANALYSIS")
    print("=" * 60)
    
    df['order_month'] = df['order_date'].dt.to_period('M')
    df['customer_month'] = df.groupby('customer_id')['order_date'].transform('min').dt.to_period('M')
    
    # Create cohort table
    cohort_data = df.groupby(['customer_month', 'order_month']).agg({'customer_id': 'nunique'}).reset_index()
    cohort_data['cohort_age'] = (cohort_data['order_month'] - cohort_data['customer_month']).apply(lambda x: x.n)
    
    cohort_table = cohort_data.pivot_table(
        values='customer_id',
        index='customer_month',
        columns='cohort_age',
        aggfunc='sum'
    )
    
    # Calculate retention rates
    cohort_sizes = cohort_table.iloc[:, 0]
    retention_table = cohort_table.divide(cohort_sizes, axis=0) * 100
    
    print("\nCohort Retention Table (% of cohort):")
    print(retention_table.round(1))
    
    return retention_table


# EXERCISE 4: Customer Lifetime Value (CLV) analysis
def calculate_customer_lifetime_value(df):
    """Calculate and analyze customer lifetime value"""
    
    print("\n" + "=" * 60)
    print("CUSTOMER LIFETIME VALUE (CLV) ANALYSIS")
    print("=" * 60)
    
    # Calculate CLV metrics
    clv_data = df.groupby('customer_id').agg({
        'order_amount': ['sum', 'mean', 'count'],
        'order_date': ['min', 'max']
    }).reset_index()
    
    clv_data.columns = ['customer_id', 'total_lifetime_value', 'avg_order_value', 'order_count', 'first_order_date', 'last_order_date']
    
    # Calculate customer lifetime in days
    clv_data['customer_lifetime_days'] = (clv_data['last_order_date'] - clv_data['first_order_date']).dt.days
    
    # Calculate average order frequency per month
    clv_data['orders_per_month'] = clv_data['order_count'] / (clv_data['customer_lifetime_days'] / 30 + 1)
    
    print("\nCLV Statistics:")
    print(clv_data[['total_lifetime_value', 'avg_order_value', 'order_count', 'orders_per_month']].describe())
    
    # Segment customers by CLV
    clv_data['clv_segment'] = pd.qcut(clv_data['total_lifetime_value'], 
                                       q=4, 
                                       labels=['Low', 'Medium', 'High', 'Very High'])
    
    print("\nCustomer Distribution by CLV Segment:")
    print(clv_data['clv_segment'].value_counts().sort_index())
    
    # Visualize CLV distribution
    plt.figure(figsize=(12, 4))
    
    plt.subplot(1, 2, 1)
    plt.hist(clv_data['total_lifetime_value'], bins=30, edgecolor='black')
    plt.xlabel('Total Lifetime Value ($)')
    plt.ylabel('Number of Customers')
    plt.title('Customer Lifetime Value Distribution')
    
    plt.subplot(1, 2, 2)
    clv_data['clv_segment'].value_counts().plot(kind='bar')
    plt.xlabel('CLV Segment')
    plt.ylabel('Number of Customers')
    plt.title('Customer Distribution by CLV Segment')
    
    plt.tight_layout()
    plt.savefig('outputs/clv_analysis.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return clv_data


# EXERCISE 5: Business metrics calculation
def calculate_business_metrics(df):
    """Calculate key business metrics"""
    
    print("\n" + "=" * 60)
    print("KEY BUSINESS METRICS")
    print("=" * 60)
    
    # Revenue metrics
    total_revenue = df['order_amount'].sum()
    avg_order_value = df['order_amount'].mean()
    median_order_value = df['order_amount'].median()
    
    # Customer metrics
    unique_customers = df['customer_id'].nunique()
    repeat_customers = len(df[df.groupby('customer_id')['order_id'].transform('count') > 1]['customer_id'].unique())
    repeat_rate = repeat_customers / unique_customers * 100
    
    # Frequency metrics
    orders_per_customer = df.shape[0] / unique_customers
    
    # Growth metrics (assuming we have date data)
    df['order_date'] = pd.to_datetime(df['order_date'])
    monthly_revenue = df.groupby(df['order_date'].dt.to_period('M'))['order_amount'].sum()
    mom_growth = monthly_revenue.pct_change().mean() * 100
    
    print(f"\nRevenue Metrics:")
    print(f"  Total Revenue: ${total_revenue:,.2f}")
    print(f"  Average Order Value (AOV): ${avg_order_value:.2f}")
    print(f"  Median Order Value: ${median_order_value:.2f}")
    
    print(f"\nCustomer Metrics:")
    print(f"  Total Unique Customers: {unique_customers:,}")
    print(f"  Repeat Customers: {repeat_customers:,}")
    print(f"  Repeat Customer Rate: {repeat_rate:.1f}%")
    print(f"  Orders per Customer: {orders_per_customer:.2f}")
    
    print(f"\nGrowth Metrics:")
    print(f"  Month-over-Month Revenue Growth: {mom_growth:.1f}%")
    
    return {
        'total_revenue': total_revenue,
        'aov': avg_order_value,
        'unique_customers': unique_customers,
        'repeat_rate': repeat_rate
    }


# ============================================
# MAIN EXECUTION
# ============================================

if __name__ == "__main__":
    print("Amazon Data Analyst Prep - Python Module")
    print("=" * 60)
    
    # Load and clean data
    df = load_and_inspect_data()
    df = handle_missing_values(df)
    df = remove_duplicates(df)
    df = convert_data_types(df)
    issues = validate_data_quality(df)
    
    # Transform and prepare
    df = transform_date_features(df)
    df = clean_string_data(df)
    df = create_derived_features(df)
    
    # Exploratory analysis
    descriptive_statistics(df)
    analyze_distributions(df)
    correlation_analysis(df)
    detect_outliers(df)
    analyze_categories(df)
    
    # Statistical analysis
    hypothesis_testing_example(df)
    ab_testing_example(df)
    retention = cohort_analysis(df)
    clv = calculate_customer_lifetime_value(df)
    metrics = calculate_business_metrics(df)
    
    print("\n" + "=" * 60)
    print("Analysis Complete!")
    print("=" * 60)
