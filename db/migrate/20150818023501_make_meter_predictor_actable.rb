class MakeMeterPredictorActable < ActiveRecord::Migration
  def change
    change_table :meter_predictors do |t|
      t.actable
    end
  end
end
