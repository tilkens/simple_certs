class MakeGenerationIdUniqueInCertificates < ActiveRecord::Migration[8.0]
  def change
    remove_index :certificates, :generation_id
    add_index :certificates, :generation_id, unique: true
  end
end
