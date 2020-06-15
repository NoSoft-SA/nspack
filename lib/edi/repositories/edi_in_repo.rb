# frozen_string_literal: true

module EdiApp
  class EdiInRepo < BaseRepo
    crud_calls_for :edi_in_transactions, name: :edi_in_transaction, wrapper: EdiInTransaction

    def mark_incomplete_transactions_as_reprocessed(id, flow_type, file_name)
      DB[:edi_in_transactions]
        .where(flow_type: flow_type,
               complete: false,
               file_name: file_name)
        .exclude(id: id)
        .update(reprocessed: true)
    end

    def file_path_for_edi_in_transaction(id)
      tran = find_edi_in_transaction(id)
      path = if tran.complete
               Pathname.new(AppConst::EDI_RECEIVE_DIR).parent + 'processed'
             else
               Pathname.new(AppConst::EDI_RECEIVE_DIR).parent + 'process_errors'
             end
      File.join(path, tran.file_name)
    end

    def log_edi_in_complete(id, message, edi_result)
      change_set = edi_result.to_h.merge(complete: true, error_message: message)
      update_edi_in_transaction(id, change_set)
    end

    def log_edi_in_failed(id, message, instance, edi_result)
      msg = if instance.empty?
              message
            else
              "#{message}\n#{instance}"
            end
      change_set = edi_result.to_h.merge(error_message: msg)
      update_edi_in_transaction(id, change_set)
    end

    def log_edi_in_error(id, exception, edi_result)
      change_set = edi_result.to_h.merge(error_message: exception.message, backtrace: exception.backtrace.join("\n"))
      update_edi_in_transaction(id, change_set)
    end

    def match_data_on(id, flow_type, match_data)
      ids = DB[:edi_in_transactions]
            .where(flow_type: flow_type,
                   complete: false,
                   reprocessed: false,
                   match_data: match_data)
            .exclude(id: id)
            .select_map(:id)
      return if ids.empty?

      DB[:edi_in_transactions].where(id: ids).update(newer_edi_received: true, reprocessed: true)
    end

    def match_data_on_list(id, flow_type, match_data)
      recs = DB[:edi_in_transactions]
             .where(flow_type: flow_type,
                    complete: false,
                    reprocessed: false)
             .exclude(id: id)
             .select_map(%i[id match_data])
      return if recs.empty?

      ids = recs.reject { |r| ((r.last || '').split(',') & match_data).empty? }.map(&:first)
      DB[:edi_in_transactions].where(id: ids).update(newer_edi_received: true, reprocessed: true)
    end

    def get_variant_id(table_name, variant_code)
      DB[:masterfile_variants].where(masterfile_table: table_name.to_s, variant_code: variant_code).get(:masterfile_id)
    end

    def get_case_insensitive_match(table_name, args)
      ds = DB[table_name]
      args.each do |k, v|
        ds = if v.is_a?(String)
               ds.where(Sequel.function(:upper, k) => v.upcase)
             else
               ds.where(k => v)
             end
      end
      values = ds.select_map(:id)
      raise Crossbeams::FrameworkError, 'Method must return only one record' if values.length > 1

      values.first
    end
  end
end
