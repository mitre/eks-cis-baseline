control 'eks-cis-4.1.6' do
  title 'Ensure that Service Account Tokens are only mounted where necessary'
  desc  "Service accounts tokens should not be mounted in pods except where the
workload running in the pod explicitly needs to communicate with the API server"
  desc  'rationale', "
    Mounting service account tokens inside pods can provide an avenue for
privilege escalation attacks where an attacker is able to compromise a single
pod in the cluster.

    Avoiding mounting these tokens removes this attack avenue.
  "
  desc 'check', "
    Review pod and service account objects in the cluster and ensure that the
option below is set, unless the resource explicitly requires this access.

    ```
    automountServiceAccountToken: false
    ```
  "
  desc  'fix', "Modify the definition of pods and service accounts which do not
need to mount service account tokens to disable it."
  impact 0.5
  tag severity: 'medium'
  tag gtitle: nil
  tag gid: nil
  tag rid: nil
  tag stig_id: nil
  tag fix_id: nil
  tag cci: nil
  tag nist: ['AC-6 (9)', 'CM-2']
  tag cis_level: 1
  tag cis_controls: [
    { '6' => ['5.1'] },
    { '7' => ['5.2'] }
  ]
  tag cis_rid: '4.1.6'

  parse_options = {
    assignment_regex: /^\s*([^\s]+?)\s+([^\s]+?)\s*$/,
  }

  allowlist_pods = input('allowlist_pods')

  pods = command("kubectl get pods --all-namespaces -o=custom-columns=':.metadata.name,:.spec.automountServiceAccountToken' --no-headers")
  pods_with_automount_tokens = parse_config(pods.stdout, parse_options)
                               .params.select { |_key, value| value != 'false' }.keys

  unauthorized_pods_with_automount_tokens = pods_with_automount_tokens.reject { |pod| allowlist_pods.any? { |allowed| (Regexp.new allowed).match?(pod) } }

  service_accounts = command("kubectl get serviceaccounts --all-namespaces -o=custom-columns=':.metadata.name,:.automountServiceAccountToken' --no-headers")
  sa_with_automount_tokens = parse_config(service_accounts.stdout, parse_options)
                             .params.select { |_key, value| value != 'false' }.keys

  unauthorized_sa_with_automount_tokens = sa_with_automount_tokens - input('allowlist_service_accounts')

  describe 'List of pods with automount service account token setting' do
    subject { unauthorized_pods_with_automount_tokens }
    it 'should be empty' do
      fail_msg = "List of pods with automountServiceAccountToken setting: #{unauthorized_pods_with_automount_tokens.join(', ')}"
      expect(unauthorized_pods_with_automount_tokens).to be_empty, fail_msg
    end
  end

  describe 'List of service accounts with automount service account token setting' do
    subject { unauthorized_sa_with_automount_tokens }
    it 'should be empty' do
      fail_msg = "List of service accounts with automountServiceAccountToken setting: #{unauthorized_sa_with_automount_tokens.join(', ')}"
      expect(unauthorized_sa_with_automount_tokens).to be_empty, fail_msg
    end
  end
end
