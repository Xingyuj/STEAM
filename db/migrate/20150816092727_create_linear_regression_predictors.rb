class CreateLinearRegressionPredictors < ActiveRecord::Migration
  def change
    create_table :linear_regression_predictors do |t|
      t.decimal :a # standard equation (y= a + bx)
      t.decimal :b

      t.timestamps null: false
    end
  end
end
