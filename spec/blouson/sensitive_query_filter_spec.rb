require 'spec_helper'

RSpec.describe Blouson::SensitiveQueryFilter do
  describe 'StatementInvalidErrorFilter' do
      def error
        model_class.where(condition).first
      rescue => e
        return e
      end

      before do
        dummy_error = Class.new(ActiveRecord::StatementInvalid) do
          prepend Blouson::SensitiveQueryFilter::StatementInvalidErrorFilter
        end
        stub_const('ActiveRecord::StatementInvalid', dummy_error)
      end

    context 'with query to sensitive table' do
      let(:model_class) { SecureUser }
      let(:email) { 'alice@example.com' }
      let(:condition) { { invalid_column: email } }

      it 'filters SQL statement' do
        if Rails::VERSION::MAJOR >= 6
          expect { model_class.where(condition).first }.to raise_error(/\[FILTERED\]/)
        else
          expect { model_class.where(condition).first }.to raise_error(/SELECT.*\[FILTERED\]/)
        end
      end

      it 'filters to_s message' do
        if Rails::VERSION::MAJOR >= 6
          expect(error.to_s).not_to include(email)
          expect(error.to_s).to include('[FILTERED]')
        else
          expect(error.to_s).to include('SELECT')
          expect(error.to_s).not_to include(email)
          expect(error.to_s).to include('[FILTERED]')
        end
      end

      it 'filters inspect message' do
        if Rails::VERSION::MAJOR >= 6
          expect(error.inspect).to include('[FILTERED]')
        else
          expect(error.to_s).to include('SELECT')
          expect(error.to_s).not_to include(email)
          expect(error.inspect).to include('[FILTERED]')
        end
      end

      if Rails::VERSION::MAJOR >= 6
        it 'filters sql message' do
          expect(error.sql).to include('SELECT')
          expect(error.sql).not_to include(email)
          expect(error.sql).to include('[FILTERED]')
        end
      end

      it 'filters double quoted queries' do
        error = nil
        begin
          ActiveRecord::Base.connection.execute(%!SELECT * FROM secure_users WHERE invalid_column = "#{email}"!)
        rescue => e
          error = e
        end
        if Rails::VERSION::MAJOR >= 6
          expect(error.to_s).not_to include(email)
          expect(error.to_s).to include('[FILTERED]')

          expect(error.sql).to include('SELECT')
          expect(error.sql).not_to include(email)
          expect(error.sql).to include('[FILTERED]')
        else
          expect(error.to_s).to include('SELECT')
          expect(error.to_s).not_to include(email)
          expect(error.to_s).to include('[FILTERED]')
        end
      end

      context 'with quote escaped query' do
        let(:email) { "'alice'@example'.com''" }

        it 'filters sensitive data' do
          if Rails::VERSION::MAJOR >= 6
            expect(error.to_s).not_to include('alice')

            expect(error.sql).to include('SELECT')
            expect(error.sql).not_to include('alice')
            expect(error.sql).to include("`secure_users`.`invalid_column` = '[FILTERED]' ")
          else
            expect(error.to_s).to include('SELECT')
            expect(error.to_s).not_to include('alice')
            expect(error.to_s).to include("`secure_users`.`invalid_column` = '[FILTERED]' ")
          end
        end
      end

      context 'with multiple quoted values' do
        let(:email) { "'alice'@example'.com''" }
        let(:condition) { { invalid_column: email, email2: email } }

        it 'filters sensitive data' do
          if Rails::VERSION::MAJOR >= 6
            expect(error.to_s).not_to include('alice')

            expect(error.sql).to include('SELECT')
            expect(error.sql).not_to include('alice')
            expect(error.sql).to include("`secure_users`.`invalid_column` = '[FILTERED]' ")
            expect(error.sql).to include("`secure_users`.`email2` = '[FILTERED]' ")
          else
            expect(error.to_s).to include('SELECT')
            expect(error.to_s).not_to include('alice')
            expect(error.to_s).to include("`secure_users`.`invalid_column` = '[FILTERED]' ")
            expect(error.to_s).to include("`secure_users`.`email2` = '[FILTERED]' ")
          end
        end
      end

      context 'with sensitive value in Mysql2::Error' do
        before do
          dummy_error = Class.new(ActiveRecord::RecordNotUnique) do
            prepend Blouson::SensitiveQueryFilter::StatementInvalidErrorFilter
          end
          stub_const('ActiveRecord::RecordNotUnique', dummy_error)

          if Rails::VERSION::MAJOR >= 7 && Rails::VERSION::MINOR >= 1
            allow_any_instance_of(ActiveRecord::ConnectionAdapters::Mysql2Adapter).to receive(:log) do |_, sql, name = "SQL", binds = [], _ = [], _ = nil, async: false, &block|
              begin
                block.call
              rescue ActiveRecord::RecordNotUnique => ex
                if ex.cause.is_a?(Mysql2::Error)
                  ex.cause.extend(Blouson::SensitiveQueryFilter::Mysql2Filter)
                elsif $!.is_a?(Mysql2::Error)
                  $!.extend(Blouson::SensitiveQueryFilter::Mysql2Filter)
                end
                raise ex.set_query(sql, binds)
              end
            end
          end
          model_class.create!(email: email, email2: email)
        end

        after do
          model_class.delete_all
        end

        it 'filters sensitive data' do
          expect { model_class.create!(email: email, email2: email) }.to raise_error { |e|
            expect(e).to be_a(ActiveRecord::RecordNotUnique)
            if Rails::VERSION::MAJOR >= 6
              expect(e.message).to_not include('alice')

              expect(e.sql).to include('INSERT INTO `secure_users` ')
              expect(e.sql).to_not include('alice')
            else
              expect(e.message).to include('INSERT INTO `secure_users` ')
              expect(e.message).to_not include('alice')
            end
          }
        end

        it 'filters sensitive data in Exception#cause' do
          expect { model_class.create!(email: email, email2: email) }.to raise_error { |e|
            mysql2_error = e.cause
            expect(mysql2_error).to be_a(Mysql2::Error)
            expect(mysql2_error.message).to_not include('alice')
          }
        end
      end
    end

    context 'with query to insensitive table' do
      let(:model_class) { User }
      let(:name) { 'alice' }
      let(:condition) { { invalid_column: name } }

      it 'does not filter SQL statement' do
        if Rails::VERSION::MAJOR >= 6
          expect { model_class.where(condition).first }.to raise_error(/Unknown column 'users.invalid_column'/)
        else
          expect { model_class.where(condition).first }.to raise_error(/Unknown column 'users.invalid_column'/)
          expect { model_class.where(condition).first }.to raise_error(/SELECT.*#{name}/)
        end
      end

      it 'does not filter to_s' do
        if Rails::VERSION::MAJOR >= 6
          expect(error.to_s).not_to include('[FILTERED]')
        else
          expect(error.to_s).to include('SELECT')
          expect(error.to_s).to include(name)
          expect(error.to_s).not_to include('[FILTERED]')
        end
      end

      it 'does not filter inspect message' do
        if Rails::VERSION::MAJOR >= 6
          expect(error.inspect).not_to include('[FILTERED]')
        else
          expect(error.to_s).to include('SELECT')
          expect(error.to_s).to include(name)
          expect(error.inspect).not_to include('[FILTERED]')
        end
      end

      if Rails::VERSION::MAJOR >= 6
        it 'does not filter sql message' do
          expect(error.sql).to include('SELECT')
          expect(error.sql).to include(name)
          expect(error.sql).not_to include('[FILTERED]')
        end
      end

      context 'with non-sensitive value in Mysql2::Error' do
        before do
          dummy_error = Class.new(ActiveRecord::RecordNotUnique) do
            prepend Blouson::SensitiveQueryFilter::StatementInvalidErrorFilter
          end
          stub_const('ActiveRecord::RecordNotUnique', dummy_error)

          if Rails::VERSION::MAJOR >= 7 && Rails::VERSION::MINOR >= 1
            allow_any_instance_of(ActiveRecord::ConnectionAdapters::Mysql2Adapter).to receive(:log) do |_, sql, name = "SQL", binds = [], _ = [], _ = nil, async: false, &block|
              begin
                block.call
              rescue ActiveRecord::RecordNotUnique => ex
                if ex.cause.is_a?(Mysql2::Error)
                  ex.cause.extend(Blouson::SensitiveQueryFilter::Mysql2Filter)
                elsif $!.is_a?(Mysql2::Error)
                  $!.extend(Blouson::SensitiveQueryFilter::Mysql2Filter)
                end
                raise ex.set_query(sql, binds)
              end
            end
          end

          model_class.create!(name: name)
        end

        after do
          model_class.delete_all
        end

        it 'does not filter message' do
          expect { model_class.create!(name: name) }.to raise_error { |e|
            expect(e).to be_a(ActiveRecord::RecordNotUnique)

            if Rails::VERSION::MAJOR >= 6
              expect(e.message).to include(name)
              expect(e.message).to_not include('[FILTERED]')

              expect(e.sql).to include('INSERT INTO `users` ')
              expect(e.sql).to include(name)
              expect(e.sql).to_not include('[FILTERED]')
            else
              expect(e.message).to include('INSERT INTO `users` ')
              expect(e.message).to include(name)
              expect(e.message).to_not include('[FILTERED]')
            end
          }
        end

        it 'does not filter message in Exception#cause' do
          expect { model_class.create!(name: name) }.to raise_error { |e|
            mysql2_error = e.cause
            expect(mysql2_error).to be_a(Mysql2::Error)
            expect(e.message).to include(name)
            expect(e.message).to_not include('[FILTERED]')
          }
        end
      end
    end

    context 'on no database error' do
      before do
        dummy_nodb_error = Class.new(ActiveRecord::StatementInvalid)
        stub_const('ActiveRecord::NoDatabaseError', dummy_nodb_error)
      end

      it 'raises ActiveRecord::NoDatabaseError' do
        error = nil
        begin
          raise ActiveRecord::NoDatabaseError
        rescue => e
          error = e
        end
        expect(error.to_s).to eq('ActiveRecord::NoDatabaseError')
        expect(error.to_s).not_to include('[FILTERED]')
      end
    end
  end
end
